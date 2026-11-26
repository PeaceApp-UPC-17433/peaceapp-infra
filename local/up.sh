#!/usr/bin/env bash
# Levanta PeaceApp en un cluster kind local con el mismo chart que usa AKS.
# Requisitos: docker, kind, kubectl y helm (pueden ir en otra carpeta: TOOLS=~/k8s-tools ./local/up.sh)
# y las imagenes locales peaceapp/<servicio>:local (las de peaceapp-platform re-etiquetadas).
set -euo pipefail
cd "$(dirname "$0")/.."
TOOLS="${TOOLS:-}"; [[ -n "$TOOLS" ]] && export PATH="$TOOLS:$PATH"

NS=peaceapp
SERVICES=(identity-service incident-service trust-service alerts-service community-service notification-service api-gateway peaceapp-appweb)
INGRESS_NGINX=controller-v1.15.1
METRICS_SERVER=v0.9.1

if ! kind get clusters | grep -qx peaceapp; then
  kind create cluster --config local/kind-config.yaml
fi
kubectl config use-context kind-peaceapp >/dev/null

echo "== Addons: ingress-nginx y metrics-server (el HPA lo necesita)"
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX}/deploy/static/provider/kind/deploy.yaml" >/dev/null
kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER}/components.yaml" >/dev/null
# kind usa certificados autofirmados en el kubelet
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null || true
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s

echo "== Imagenes"
for s in "${SERVICES[@]}"; do kind load docker-image "peaceapp/$s:local" --name peaceapp; done

echo "== Namespace, Secrets, Postgres y RabbitMQ"
kubectl apply -f deploy/namespace.yaml
kubectl -n $NS create secret generic rabbitmq-credentials \
  --from-literal=RABBITMQ_DEFAULT_USER=peaceapp --from-literal=RABBITMQ_DEFAULT_PASS=peaceapp \
  --dry-run=client -o yaml | kubectl apply -f -
JWT=local-dev-secret-change-me-local-dev-secret-change-me
for s in "${SERVICES[@]}"; do
  args=(--from-literal=RABBIT_USER=peaceapp --from-literal=RABBIT_PASSWORD=peaceapp)
  db="${s%-service}"
  case "$s" in
    api-gateway|peaceapp-appweb) ;;
    *) args+=(--from-literal=DB_URL="jdbc:postgresql://postgres:5432/${db}_db"
              --from-literal=DB_USERNAME="$db" --from-literal=DB_PASSWORD="$db"
              --from-literal=SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=4
              --from-literal=SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=1) ;;
  esac
  case "$s" in
    identity-service) args+=(--from-literal=JWT_SECRET=$JWT --from-literal=OTP_SECRET=local-dev-otp-secret-change-me-please-0123456789) ;;
    api-gateway)      args+=(--from-literal=JWT_SECRET=$JWT) ;;
    notification-service) args+=(--from-literal=NOTIFICATION_HASH_KEY=local-dev-fingerprint-key-change-me) ;;
  esac
  kubectl -n $NS create secret generic "$s-env" "${args[@]}" --dry-run=client -o yaml | kubectl apply -f -
done
kubectl apply -f local/postgres.yaml
kubectl -n $NS rollout status deployment/postgres --timeout=180s
helm upgrade --install rabbitmq charts/rabbitmq -n $NS --wait --timeout 5m

echo "== Microservicios (chart charts/service)"
for s in "${SERVICES[@]}"; do
  extra=(); [[ -f "local/values/$s.yaml" ]] && extra=(-f "local/values/$s.yaml")
  helm upgrade --install "$s" charts/service -n $NS \
    -f "deploy/values/$s.yaml" -f local/values/common.yaml "${extra[@]}" \
    --set image.repository="peaceapp/$s" &
done
wait
for s in "${SERVICES[@]}"; do kubectl -n $NS rollout status "deployment/$s" --timeout=6m; done

echo
echo "Listo. Web: https://peaceapp.localtest.me  API: https://api.peaceapp.localtest.me (certificado autofirmado)"
echo "Borrar todo: kind delete cluster --name peaceapp"
