# 3.3 Infrastructure as Code

El aprovisionamiento de la infraestructura cloud de PeaceApp se codifica con
**Terraform** (proveedor `hashicorp/azurerm`). Se eligió Terraform sobre Azure
Bicep, AWS CloudFormation/CDK o Pulumi por los mismos criterios que ya se
usaron para justificar el resto del stack técnico (sección 2.1, Tabla 38):
portabilidad entre proveedores cloud (RES-03), costo cero por ser open source,
y madurez/comunidad del ecosistema — Bicep, aunque más simple, queda atado a
Azure y por eso es menos defendible frente al criterio de portabilidad que el
propio equipo declaró para el resto de herramientas.

El código vive en el repositorio `peaceapp-infra`
(https://github.com/PeaceApp-UPC-17433/peaceapp-infra), organizado en tres
módulos que reproducen la infraestructura ya documentada en la sección 3.4:

| Recurso | Módulo | Corresponde a |
| --- | --- | --- |
| Resource group `rg-peaceapp` | `modules/resource-group` | Sección 3.4.2 |
| AKS `aks-peaceapp` (Free tier, 1 nodo `Standard_D2ads_v7`, North Central US) | `modules/aks` | Evidencia 4, 5 |
| PostgreSQL Flexible Server `peaceapp-pg-17433` (Burstable B1ms, PostgreSQL 16) con bases `identity_db` e `incident_db` | `modules/postgres` | Evidencia 10, 11 |

Los manifiestos de Kubernetes (Deployments, Services, Secrets) y el namespace
`peaceapp` no se incluyen en este Terraform porque se crean con `kubectl`
después de que el clúster existe (secciones 3.4.2 y 3.8) y no son recursos de
Azure Resource Manager.

**Nota de corrección.** El texto de la sección 3.4.1 afirma que se eligió la
región Brazil South, pero la Evidencia 3 muestra que esa región falló por
cuota de vCPU y la Evidencia 4 confirma que el clúster real corre en North
Central US. El código de este módulo usa North Central US, la región
verificada; se recomienda corregir el texto de 3.4.1 para que no contradiga
la evidencia.

## Código

Fragmento del módulo `aks` (`modules/aks/main.tf`):

```hcl
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  # Plano de control sin costo (RES-05: proyecto academico sin presupuesto).
  sku_tier = "Free"

  default_node_pool {
    name       = "nodepool1"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
```

Fragmento del módulo `postgres` (`modules/postgres/main.tf`), con una base de
datos por microservicio (CA-02):

```hcl
resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name

  version    = "16"
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
}

resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.database_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
```

La contraseña del administrador nunca se escribe en un archivo versionado: se
pasa por la variable de entorno `TF_VAR_postgres_admin_password` (CA-06,
TS-08), igual que `JWT_SECRET` en los microservicios.

## Evidencia

**Formateo e inicialización** (`terraform fmt` + `terraform init -backend=false`,
no requieren credenciales de Azure):

```
$ terraform fmt -recursive
main.tf

$ terraform init -backend=false
Initializing modules...
- aks in modules\aks
- resource_group in modules\resource-group
- postgres in modules\postgres

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.116"...
- Installing hashicorp/azurerm v3.117.1...
- Installed hashicorp/azurerm v3.117.1 (signed by HashiCorp)

Terraform has been successfully initialized!
```

**Validación sintáctica y de tipos** (`terraform validate`):

```
$ terraform validate
Success! The configuration is valid.
```

**[PENDIENTE — agregar captura propia]** `terraform plan` ejecutado con
`az login` contra la suscripción Azure for Students real (ver README del
repositorio para el procedimiento exacto). Debe mostrar el resumen
`Plan: X to add, 0 to change, 0 to destroy`.

**Nota metodológica.** No se ejecutó `terraform apply`: el clúster AKS y el
servidor PostgreSQL de la sección 3.4 ya existen, fueron creados
manualmente, y el crédito de Azure for Students es limitado. Aplicar este
plan crearía una copia duplicada de la infraestructura y repetiría el riesgo
de cuota de vCPU ya documentado en Brazil South (Evidencia 3). `terraform
plan` no modifica nada en Azure, no tiene costo, y es evidencia suficiente de
que el código describe correctamente la infraestructura real. Administrar la
infraestructura ya existente sin recrearla (`terraform import`) queda
identificado como mejora pendiente para una entrega posterior.
