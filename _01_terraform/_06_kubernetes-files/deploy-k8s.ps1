# EKS microservices deploy - Windows PowerShell
# macOS / Linux: ./deploy-k8s.sh
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path "secrets.yaml")) {
    Write-Error "secrets.yaml bulunamadi. Once: cp secrets.example.yaml secrets.yaml"
}

# dev vb. namespace'lerdeki yanlis postgres kopyasini sil (2. EBS volume olusmasin)
Write-Host 'Postgres PVC tekillestiriliyor - yalnizca default/postgres-data kalacak...'
kubectl delete deployment postgres -n dev --ignore-not-found 2>$null
kubectl delete pvc postgres-data -n dev --ignore-not-found 2>$null
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$pvcOutput = kubectl get pvc -A --no-headers 2>&1
$ErrorActionPreference = $prevEap
$extraPvcs = @($pvcOutput | Where-Object {
        $_ -is [string] -and $_ -notmatch 'No resources found' -and $_ -match '\spostgres-data\s'
    } | ForEach-Object { ($_ -split '\s+', 2)[0] } | Where-Object { $_ -and $_ -ne 'default' })
foreach ($ns in $extraPvcs) {
    Write-Warning "postgres-data PVC bulundu namespace=$ns - siliniyor. Yalnizca default kullanin."
    kubectl delete deployment postgres -n $ns --ignore-not-found 2>$null
    kubectl delete pvc postgres-data -n $ns --ignore-not-found 2>$null
}

Write-Host "Secrets uygulaniyor..."
kubectl apply -f secrets.yaml


# === YENI EKLENECEK KISIM ===
# Eski tamamlanmış Job'ı sil ki kustomize apply edildiğinde yeniden tetiklensin
Write-Host 'Eski Postgres Init Job kalintilari temizleniyor...'
kubectl delete job postgres-init-job -n default --ignore-not-found 2>$null
# ============================


Write-Host 'Manifestler uygulaniyor - kustomize namespace default...'
kubectl apply -k .
# default/postgres-data PVC asla silinmez; apply mevcut volume baglantisini surdurur
if (kubectl get pvc postgres-data -n default 2>$null) {
    Write-Host 'Postgres PVC: default/postgres-data - mevcut EBS volume korunur'
}

Write-Host 'Eureka yeniden baslatiliyor - standalone mod...'
kubectl scale deployment config-server-local account-service api-gateway-service ledger-service fraud-service notification-service --replicas=0
kubectl apply -f eureka-server-config.yaml
kubectl apply -f dashboardeurekaserver.yaml
kubectl rollout restart deployment dashboard-eureka-server
kubectl rollout status deployment dashboard-eureka-server --timeout=180s
Start-Sleep -Seconds 30

Write-Host "Microservisler baslatiliyor..."
kubectl scale deployment config-server-local account-service api-gateway-service ledger-service fraud-service notification-service --replicas=1
$clients = @(
    "config-server-local",
    "api-gateway-service",
    "account-service",
    "ledger-service",
    "fraud-service",
    "notification-service"
)
foreach ($dep in $clients) {
    kubectl rollout status deployment $dep --timeout=180s
}

Write-Host "Eureka kayitlari senkronize ediliyor..."
kubectl rollout restart deployment dashboard-eureka-server
kubectl rollout status deployment dashboard-eureka-server --timeout=180s
Start-Sleep -Seconds 30

$eurekaClients = @(
    "config-server-local",
    "api-gateway-service",
    "account-service",
    "ledger-service",
    "fraud-service",
    "notification-service"
)
kubectl rollout restart deployment @eurekaClients
foreach ($dep in $eurekaClients) {
    kubectl rollout status deployment $dep --timeout=180s
}
Start-Sleep -Seconds 20
Write-Host 'Eureka kontrol: kubectl run eureka-curl --rm -it --restart=Never --image=curlimages/curl -- curl -s http://dashboard-eureka-server:8761/eureka/apps'

Write-Host "LoadBalancer DNS bekleniyor - en fazla 5 dk..."
$deadline = (Get-Date).AddMinutes(5)
$hostname = $null
while ((Get-Date) -lt $deadline) {
    $hostname = kubectl get svc api-gateway-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($hostname) { break }
    Start-Sleep -Seconds 10
}

if (-not $hostname) {
    Write-Warning "LoadBalancer DNS henuz hazir degil. Kontrol: kubectl get svc api-gateway-service dashboard-eureka-server"
    exit 1
}

$keycloakHost = kubectl get svc keycloak -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null

Write-Host ""
Write-Host "=== Public URLs ==="
Write-Host "API Gateway : http://${hostname}/"
Write-Host "Jenkins     : http://${hostname}:8080"
Write-Host "SonarQube   : http://${hostname}:9000"
Write-Host "Eureka      : http://${hostname}:8761"
if ($keycloakHost) {
    Write-Host "Keycloak    : http://${keycloakHost}:8180/admin/master/console/"
} else {
    Write-Host "Keycloak    : kubectl get svc keycloak"
}
