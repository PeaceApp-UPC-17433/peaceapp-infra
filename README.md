# peaceapp-infra

Infraestructura de PeaceApp en Azure con Terraform.

| | Dominio |
|---|---|
| Web | `peaceapp.angelanampa.dev` |
| API | `api.peaceapp.angelanampa.dev` |

Los registros A se crean a mano en Namecheap con la salida `dns_records`, apuntando a la IP del ingress.

## Estructura

- `infra/` raíz de Terraform. Tiene bloques `import` para el AKS y PostgreSQL que ya existen.
- `modules/` `aks`, `postgres`, `function`, `edge`, `budget`.
- `scripts/bootstrap.sh` estado remoto, identidad de GitHub por OIDC y roles. Requiere rol Owner.
- `.github/workflows/terraform.yml` fmt, validate, tests, TFLint, Trivy config (bloquea HIGH y CRITICAL), plan en PR y apply en `main`.

## Puesta en marcha

1. `az login` con rol Owner y `INFRA_REPO=PeaceApp-UPC-17433/peaceapp-infra ./scripts/bootstrap.sh`.
2. Variables del repositorio: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `TFSTATE_RG`, `TFSTATE_SA`, `BUDGET_CONTACT_EMAIL`, `INGRESS_IP` (cuando exista).
3. Local: `terraform -chdir=infra init -backend-config=...` y `plan -var-file=environments/prod.tfvars`.

## Pruebas

```bash
for d in modules/edge modules/postgres; do (cd $d && terraform init -backend=false && terraform test); done
```
