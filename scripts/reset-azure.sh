#!/usr/bin/env bash
set -euo pipefail

RG="${RG:-rg-peaceapp}"
AKS="${AKS:-aks-peaceapp}"
PG="${PG:-peaceapp-pg-17433}"

echo "Se eliminarán del grupo $RG: AKS $AKS y PostgreSQL $PG (sin datos de producción)."
read -r -p "Escribe BORRAR para continuar: " answer
[ "$answer" = "BORRAR" ] || exit 1

az aks show -g "$RG" -n "$AKS" -o none 2>/dev/null && az aks delete -g "$RG" -n "$AKS" --yes --no-wait
az postgres flexible-server show -g "$RG" -n "$PG" -o none 2>/dev/null && az postgres flexible-server delete -g "$RG" -n "$PG" --yes

az aks wait -g "$RG" -n "$AKS" --deleted 2>/dev/null || true
az resource list -g "$RG" --query "[].{name:name,type:type}" -o table
