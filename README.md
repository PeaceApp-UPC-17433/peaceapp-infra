# peaceapp-infra

Infrastructure as Code (Terraform) para la infraestructura de PeaceApp en Azure,
sección **3.3** del informe (Capítulo III). Modela los mismos recursos que ya
están corriendo manualmente (sección 3.4): resource group, clúster AKS y
Azure Database for PostgreSQL Flexible Server con una base por microservicio.

## Qué provisiona

| Recurso | Módulo | Coincide con |
| --- | --- | --- |
| Resource group `rg-peaceapp` | `modules/resource-group` | Sección 3.4.2 |
| AKS `aks-peaceapp` (Free tier, 1 nodo `Standard_D2ads_v7`, North Central US) | `modules/aks` | Evidencia 4, 5 (3.4.5) |
| PostgreSQL Flexible Server `peaceapp-pg-17433` (Burstable B1ms, PostgreSQL 16, 32 GB) con bases `identity_db` e `incident_db` | `modules/postgres` | Evidencia 10, 11 (3.4.5) |

**Nota sobre la región:** el texto de la sección 3.4.1 del informe dice que se
eligió Brazil South, pero la Evidencia 3 muestra que esa región falló por
cuota de vCPU y la Evidencia 4 confirma que el clúster real corre en
**North Central US**. Este código usa North Central US (la región real);
hay que corregir el texto de 3.4.1 para que no contradiga la evidencia.

No se incluye: Kubernetes Secrets, namespace `peaceapp`, ni los Deployments/
Services de cada microservicio — esos se crean con `kubectl` después de que el
clúster existe (así se documenta en 3.4.2 y 3.8), no son recursos de Azure
Resource Manager y por eso no son parte de este Terraform.

## Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) autenticado con la suscripción Azure for Students del equipo

## Cómo correrlo (para capturar la evidencia de 3.3)

```powershell
az login
az account set --subscription "<nombre o id de la suscripcion Azure for Students>"

cd peaceapp-infra
cp terraform.tfvars.example terraform.tfvars   # completar o dejar los defaults
$env:TF_VAR_postgres_admin_password = "<una contrasena que cumpla la politica de Azure>"

terraform init
terraform fmt -check
terraform validate
terraform plan -out=plan.tfplan
```

Captura de pantalla recomendada para el informe: la salida completa de
`terraform plan`, mostrando los recursos que se crearían (`Plan: X to add`).

**Importante — no corrimos `terraform apply`.** El clúster AKS y el servidor
PostgreSQL ya existen (creados manualmente, sección 3.4) y el crédito de
Azure for Students es limitado; aplicar este plan crearía una copia duplicada
y consumiría más crédito, repitiendo el riesgo de cuota de vCPU que ya
tuvieron en Brazil South. `terraform plan` no modifica nada en Azure y no
tiene costo — es evidencia suficiente para esta entrega.

Si más adelante el equipo quiere que Terraform administre los recursos reales
sin recrearlos, la alternativa es `terraform import` sobre cada recurso
existente en vez de `apply`; no se hizo aquí porque tiene más riesgo de tocar
infraestructura que ya está en uso.

## Estado (state)

Este repo usa backend local (`terraform.tfstate`, ignorado por git) porque el
alcance del curso no requiere colaboración concurrente sobre el mismo state.
Si el equipo corre `plan`/`apply` desde más de una máquina, conviene migrar a
un backend remoto (un Storage Account de Azure) para evitar conflictos de
estado — documentado como mejora pendiente, no implementado en este avance.
