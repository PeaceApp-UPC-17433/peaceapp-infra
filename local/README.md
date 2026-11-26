# PeaceApp en Kubernetes local (kind)

Despliega los 8 servicios con el mismo chart que usa AKS (`charts/service` + `deploy/values/*`),
más Postgres y RabbitMQ dentro del cluster. Sirve para validar la orquestación sin tocar Azure.

## Levantar

```bash
# imagenes construidas por peaceapp-platform (docker compose ... build), re-etiquetadas:
for s in identity-service incident-service trust-service alerts-service community-service notification-service api-gateway; do
  docker tag "peaceapp-${s}:latest" "peaceapp/${s}:local"
done
docker tag peaceapp-web:latest peaceapp/peaceapp-appweb:local

TOOLS=~/k8s-tools ./local/up.sh   # TOOLS es opcional si kind/kubectl/helm estan en el PATH
```

- Web: https://peaceapp.localtest.me
- API: https://api.peaceapp.localtest.me (certificado autofirmado: el navegador avisa)

## Recursos por servicio

| Recurso | Origen |
|---|---|
| Namespace `peaceapp` | `deploy/namespace.yaml` (en AKS: Terraform) |
| Deployment (probes, limites, securityContext) | `charts/service/templates/deployment.yaml` |
| Service | `charts/service/templates/service.yaml` |
| Ingress (gateway y web) | `charts/service/templates/ingress.yaml` |
| ConfigMap `<svc>-config` | `charts/service/templates/configmap.yaml` |
| Secret `<svc>-env` | `local/up.sh` (en AKS: Terraform `cluster/main.tf`) |
| HPA (CPU 70%) | `charts/service/templates/hpa.yaml` |
| NetworkPolicy | `charts/service/templates/networkpolicy.yaml` |

## Comandos para las capturas

```bash
export PATH=~/k8s-tools:$PATH
kubectl get nodes -o wide
kubectl get ns
kubectl get all -n peaceapp
kubectl get ingress,configmap,secret -n peaceapp
kubectl get hpa -n peaceapp
kubectl describe deploy identity-service -n peaceapp   # probes, limites, envFrom
kubectl describe configmap identity-service-config -n peaceapp
kubectl top pods -n peaceapp
helm list -n peaceapp
```

## Autoescalado (HPA)

```bash
kubectl apply -f local/load-test.yaml
kubectl get hpa -n peaceapp -w          # identity-service sube a 2 replicas
kubectl delete -f local/load-test.yaml  # baja a 1 tras ~5 min (stabilizationWindowSeconds)
```

## Borrar

```bash
kind delete cluster --name peaceapp
```
