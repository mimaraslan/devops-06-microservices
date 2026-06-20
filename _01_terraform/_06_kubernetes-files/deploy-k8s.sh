#!/usr/bin/env bash
# EKS microservices deploy - macOS / Linux / Git Bash (Windows)
# Windows PowerShell icin: ./deploy-k8s.ps1
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f secrets.yaml ]]; then
  echo "secrets.yaml bulunamadi. Once: cp secrets.example.yaml secrets.yaml" >&2
  exit 1
fi

echo 'Postgres PVC tekillestiriliyor - yalnizca default/postgres-data kalacak...'
kubectl delete deployment postgres -n dev --ignore-not-found 2>/dev/null || true
kubectl delete pvc postgres-data -n dev --ignore-not-found 2>/dev/null || true

while IFS= read -r line; do
  [[ -z "$line" || "$line" == *"No resources found"* ]] && continue
  ns="${line%% *}"
  if [[ "$ns" != "default" && "$line" == *"postgres-data"* ]]; then
    echo "UYARI: postgres-data PVC bulundu namespace=$ns - siliniyor. Yalnizca default kullanin." >&2
    kubectl delete deployment postgres -n "$ns" --ignore-not-found 2>/dev/null || true
    kubectl delete pvc postgres-data -n "$ns" --ignore-not-found 2>/dev/null || true
  fi
done < <(kubectl get pvc -A --no-headers 2>/dev/null || true)

echo "Secrets uygulaniyor..."
kubectl apply -f secrets.yaml

echo 'Manifestler uygulaniyor - kustomize namespace default...'
kubectl apply -k .
if kubectl get pvc postgres-data -n default >/dev/null 2>&1; then
  echo 'Postgres PVC: default/postgres-data - mevcut EBS volume korunur'
fi

echo 'Eureka yeniden baslatiliyor - standalone mod...'
kubectl scale deployment config-server-local account-service api-gateway-service ledger-service fraud-service notification-service --replicas=0
kubectl apply -f eureka-server-config.yaml
kubectl apply -f dashboardeurekaserver.yaml
kubectl rollout restart deployment dashboard-eureka-server
kubectl rollout status deployment dashboard-eureka-server --timeout=180s
sleep 30

echo "Microservisler baslatiliyor..."
kubectl scale deployment config-server-local account-service api-gateway-service ledger-service fraud-service notification-service --replicas=1
clients=(
  config-server-local
  api-gateway-service
  account-service
  ledger-service
  fraud-service
  notification-service
)
for dep in "${clients[@]}"; do
  kubectl rollout status deployment "$dep" --timeout=180s
done

echo "Eureka kayitlari senkronize ediliyor..."
kubectl rollout restart deployment dashboard-eureka-server
kubectl rollout status deployment dashboard-eureka-server --timeout=180s
sleep 30

eureka_clients=(
  config-server-local
  api-gateway-service
  account-service
  ledger-service
  fraud-service
  notification-service
)
kubectl rollout restart deployment "${eureka_clients[@]}"
for dep in "${eureka_clients[@]}"; do
  kubectl rollout status deployment "$dep" --timeout=180s
done
sleep 20
echo 'Eureka kontrol: kubectl run eureka-curl --rm -it --restart=Never --image=curlimages/curl -- curl -s http://dashboard-eureka-server:8761/eureka/apps'

echo "LoadBalancer DNS bekleniyor - en fazla 5 dk..."
hostname=""
deadline=$((SECONDS + 300))
while (( SECONDS < deadline )); do
  hostname="$(kubectl get svc api-gateway-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -n "$hostname" ]]; then
    break
  fi
  sleep 10
done

if [[ -z "$hostname" ]]; then
  echo "UYARI: LoadBalancer DNS henuz hazir degil. Kontrol: kubectl get svc api-gateway-service dashboard-eureka-server" >&2
  exit 1
fi

keycloak_host="$(kubectl get svc keycloak -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

echo ""
echo "=== Public URLs ==="
echo "API Gateway : http://${hostname}/"
echo "Eureka      : http://${hostname}:8761/"
if [[ -n "$keycloak_host" ]]; then
  echo "Keycloak    : http://${keycloak_host}:8180/admin/master/console/"
else
  echo "Keycloak    : kubectl get svc keycloak"
fi
