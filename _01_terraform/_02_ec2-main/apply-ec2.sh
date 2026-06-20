#!/usr/bin/env bash
# Yerel gelistirme: macOS / Linux / Git Bash (Windows)
set -euo pipefail

cd "$(dirname "$0")"

terraform init -reconfigure
terraform validate
terraform plan -out=tfplan_ec2
terraform apply tfplan_ec2

echo ""
echo "EC2 hazir. Jenkins: http://$(terraform output -raw mydemo_public_ip):8080"
