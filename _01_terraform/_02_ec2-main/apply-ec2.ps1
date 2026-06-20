# Yerel gelistirme: Windows PowerShell
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

terraform init -reconfigure
terraform validate
terraform plan -out=tfplan_ec2
terraform apply tfplan_ec2

$ip = terraform output -raw mydemo_public_ip
Write-Host ""
Write-Host "EC2 hazir. Jenkins: http://${ip}:8080"
