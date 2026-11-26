# GitOps con Argo CD

La fuente de verdad del clúster es este repositorio. Argo CD compara lo que hay en Git con lo que corre en Kubernetes y los mantiene iguales.

## Piezas

| Archivo | Para qué sirve |
|---|---|
| `gitops/applicationset.yaml` | Genera una Application por servicio y por ambiente (dev → `peaceapp-dev`, prod → `peaceapp`). |
| `charts/service` | Chart único de los microservicios (Deployment, Service, Ingress, ConfigMap, HPA, PDB, NetworkPolicy). |
| `deploy/values/<servicio>.yaml` | Valores propios del servicio. |
| `deploy/environments/<ambiente>.yaml` | Diferencias por ambiente (réplicas, HPA, Ingress). |
| `deploy/tags/<ambiente>/<servicio>.yaml` | Versión de imagen desplegada. Es lo único que cambia en cada entrega. |
| `gitops/kind/applicationset-kind.yaml` | Variante para el clúster local `kind` (evidencias, sin tocar Azure). |

## Flujo de entrega

1. Push a `develop` del servicio: el pipeline (`pipelines/service.yml`, job `gitops`) abre un PR que sube el tag en `deploy/tags/dev`. Al fusionarse, Argo CD despliega en dev.
2. Tag `vX.Y.Z` en el servicio: el pipeline abre un PR sobre `deploy/tags/prod`. Un revisor lo aprueba (promoción entre ambientes) y Argo CD despliega en producción.

## Estrategia de despliegue

`RollingUpdate` con `maxSurge: 1` y `maxUnavailable: 0`: un pod nuevo debe estar `Ready` antes de retirar uno viejo. Si la versión nueva falla (por ejemplo la imagen no existe), los pods anteriores siguen atendiendo.

## Rollback

`git revert <commit>` del cambio de tag y push (o PR). Argo CD vuelve a la versión anterior sin intervención manual. El historial de cada Application queda en `status.history`.

## Limitaciones conocidas

- El ambiente `dev` comparte clúster con producción (una suscripción de estudiante no permite un segundo AKS); se separa por namespace. Terraform (`cluster/main.tf`) aún crea los Secrets solo para el namespace `peaceapp`, de modo que `peaceapp-dev` necesita los suyos antes de activar el ApplicationSet en Azure.
- El auto-merge del PR de dev requiere habilitar *Allow auto-merge* en este repositorio y que los controles `terraform` y `chart` sean obligatorios en la protección de ramas.
- La instalación de Argo CD en AKS (y el secreto `INFRA_REPO_TOKEN` del pipeline) no está automatizada todavía: hoy se validó en un clúster local kind.

## Argo CD en el AKS

Instalado el 26/11/2026 en el namespace `argocd` del clúster `aks-peaceapp-v2`, sin exposición pública, con límites de recursos y fijado al nodo con más holgura:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --version 10.20.0 -f gitops/argocd-aks-values.yaml
kubectl apply -f gitops/applicationset-aks.yaml   # solo cuando `main` ya tenga deploy/tags y deploy/environments
```

`gitops/applicationset-aks.yaml` define un Application por servicio **solo para producción** y con **sincronización manual**: Argo CD muestra las diferencias, pero no cambia nada hasta pedir el sync. No incluye `dev`, que no cabe en este clúster.

Antes de sincronizar un servicio por primera vez: el chart 1.1.0 añade ConfigMap y HPA y reordena `envFrom`. Conviene hacerlo de uno en uno y comprobar `kubectl rollout status`.