data "kubernetes_service_v1" "ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}

output "ingress_ip" {
  value = try(data.kubernetes_service_v1.ingress.status[0].load_balancer[0].ingress[0].ip, null)
}

output "grafana_admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}
