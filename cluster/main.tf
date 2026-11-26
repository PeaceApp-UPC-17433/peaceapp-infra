data "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_name
  resource_group_name = var.resource_group_name
}

data "azurerm_postgresql_flexible_server" "this" {
  name                = var.postgres_name
  resource_group_name = var.resource_group_name
}

data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_resource_group
    storage_account_name = var.tfstate_storage_account
    container_name       = "tfstate"
    key                  = "prod.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

locals {
  evidence_account        = data.terraform_remote_state.infra.outputs.evidence_storage_account
  postgres_admin_password = data.terraform_remote_state.infra.outputs.postgres_admin_password
  kube                    = data.azurerm_kubernetes_cluster.this.kube_config[0]

  db_services = ["identity", "incident", "trust", "alerts", "community", "notification"]
  db_url      = { for s in local.db_services : s => "jdbc:postgresql://${data.azurerm_postgresql_flexible_server.this.fqdn}:5432/${s}_db?sslmode=require" }

  secrets = {
    identity-service = {
      JWT_SECRET = random_password.jwt.result
      OTP_SECRET = random_password.otp.result
    }
    incident-service = local.evidence_account == "" ? {} : {
      EVIDENCE_STORAGE_ACCOUNT = local.evidence_account
      EVIDENCE_STORAGE_KEY     = data.azurerm_storage_account.evidence[0].primary_access_key
    }
    trust-service     = {}
    alerts-service    = {}
    community-service = {}
    notification-service = {
      RESEND_API_KEY        = var.resend_api_key
      NOTIFICATION_HASH_KEY = random_password.notification_hash.result
    }
    api-gateway = {
      JWT_SECRET = random_password.jwt.result
    }
    peaceapp-appweb = {
      MAPBOX_ACCESS_TOKEN = var.mapbox_access_token
    }
  }
}

data "azurerm_storage_account" "evidence" {
  count               = local.evidence_account == "" ? 0 : 1
  name                = local.evidence_account
  resource_group_name = var.resource_group_name
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "random_password" "otp" {
  length  = 48
  special = false
}

resource "random_password" "notification_hash" {
  length  = 48
  special = false
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "random_password" "db" {
  for_each = toset(local.db_services)
  length   = 32
  special  = false
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "ghcr_pull" {
  count = var.ghcr_token == "" ? 0 : 1

  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_token
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_token}")
        }
      }
    })
  }
}

resource "kubernetes_secret_v1" "service" {
  for_each = local.secrets

  metadata {
    name      = "${each.key}-env"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = merge(
    {
      RABBIT_USER     = "peaceapp"
      RABBIT_PASSWORD = random_password.rabbitmq.result
    },
    contains(local.db_services, trimsuffix(each.key, "-service")) ? {
      DB_URL      = local.db_url[trimsuffix(each.key, "-service")]
      DB_USERNAME = trimsuffix(each.key, "-service")
      DB_PASSWORD = random_password.db[trimsuffix(each.key, "-service")].result
    } : {},
    each.value
  )
}

resource "kubernetes_secret_v1" "rabbitmq" {
  metadata {
    name      = "rabbitmq-credentials"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = {
    RABBITMQ_DEFAULT_USER = "peaceapp"
    RABBITMQ_DEFAULT_PASS = random_password.rabbitmq.result
  }
}

resource "helm_release" "rabbitmq" {
  name      = "rabbitmq"
  namespace = kubernetes_namespace_v1.app.metadata[0].name
  chart     = "${path.module}/../charts/rabbitmq"
  atomic    = true

  depends_on = [kubernetes_secret_v1.rabbitmq]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.15.1"
  atomic           = true

  values = [yamlencode({
    controller = {
      replicaCount = 1
      service = {
        annotations = {
          "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
        }
      }
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { memory = "256Mi" }
      }
    }
  })]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.21.3"
  atomic           = true

  values = [yamlencode({
    crds = { enabled = true }
  })]
}

resource "helm_release" "issuer" {
  name      = "letsencrypt"
  namespace = "cert-manager"
  chart     = "${path.module}/../charts/issuer"
  atomic    = true

  set = [{
    name  = "email"
    value = var.letsencrypt_email
  }]

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_secret_v1" "db_admin" {
  metadata {
    name      = "postgres-admin"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = {
    password = local.postgres_admin_password
  }
}

resource "kubernetes_job_v1" "db_roles" {
  metadata {
    name      = "db-roles-${substr(sha1(join(",", [for s in local.db_services : random_password.db[s].result])), 0, 6)}"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    backoff_limit = 3

    template {
      metadata {}

      spec {
        restart_policy = "OnFailure"

        container {
          name    = "psql"
          image   = "postgres:16-alpine"
          command = ["/bin/sh", "-ec"]
          args = [<<-SH
            for svc in ${join(" ", local.db_services)}; do
              pass="$(printenv "$(echo "$svc" | tr a-z A-Z)_DB_PASSWORD")"
              psql -v ON_ERROR_STOP=1 -v svc="$svc" -v pass="$pass" --dbname postgres <<'SQL'
            SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'svc', :'pass')
            WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'svc') \gexec
            SELECT format('ALTER ROLE %I PASSWORD %L', :'svc', :'pass') \gexec
            SELECT format('GRANT %I TO CURRENT_USER', :'svc') \gexec
            SELECT format('ALTER DATABASE %I OWNER TO %I', :'svc' || '_db', :'svc') \gexec
            SQL
            done
          SH
          ]

          env {
            name  = "PGHOST"
            value = data.azurerm_postgresql_flexible_server.this.fqdn
          }
          env {
            name  = "PGUSER"
            value = var.postgres_admin_login
          }
          env {
            name  = "PGSSLMODE"
            value = "require"
          }
          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          dynamic "env" {
            for_each = local.db_services
            content {
              name  = "${upper(env.value)}_DB_PASSWORD"
              value = random_password.db[env.value].result
            }
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}

resource "random_password" "grafana" {
  length  = 24
  special = false
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "30.0.1"
  atomic           = true

  values = [yamlencode({
    alertmanager               = { enabled = false }
    "prometheus-pushgateway"   = { enabled = false }
    "kube-state-metrics"       = { enabled = false }
    "prometheus-node-exporter" = { enabled = false }
    server = {
      retention        = "3d"
      persistentVolume = { size = "4Gi" }
      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { memory = "512Mi" }
      }
    }
  })]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.5.15"
  atomic     = true

  values = [yamlencode({
    adminPassword = random_password.grafana.result
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { memory = "256Mi" }
    }
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [{
          name      = "Prometheus"
          type      = "prometheus"
          url       = "http://prometheus-server.monitoring.svc"
          isDefault = true
        }]
      }
    }
    dashboardProviders = {
      "dashboardproviders.yaml" = {
        apiVersion = 1
        providers = [{
          name    = "default"
          folder  = "PeaceApp"
          type    = "file"
          options = { path = "/var/lib/grafana/dashboards/default" }
        }]
      }
    }
    dashboards = {
      default = {
        jvm = { gnetId = 4701, revision = 10, datasource = "Prometheus" }
      }
    }
  })]

  depends_on = [helm_release.prometheus]
}
