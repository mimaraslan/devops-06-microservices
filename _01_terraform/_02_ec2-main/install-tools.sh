#!/bin/bash
# Bu script yerel Mac/Windows'ta degil, EC2 uzerinde calisir.
# Terraform null_resource provisioner (SSH) ile otomatik kopyalanir ve calistirilir.

# Hata durumunda scripti durdur
set -e

echo "🚀 Kurulum başlatılıyor (tekrar çalıştırma güvenli)..."

# 0. Paket yöneticisini temizle
sudo dnf clean all

# 1. Sistem Güncelleme ve Temel Araçlar
sudo dnf update -y
sudo dnf install -y git wget unzip curl yum-utils --allowerasing

# 2. Java 21
sudo dnf install -y java-21-amazon-corretto

# 3. Node.js ve NPM
sudo dnf install -y nodejs

# 4. Jenkins Kurulumu
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable --now jenkins

# 5. Kubernetes Araçları
if ! command -v kubectl >/dev/null 2>&1; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
else
  echo "kubectl zaten kurulu, atlaniyor."
fi

if ! command -v eksctl >/dev/null 2>&1; then
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/eksctl
else
  echo "eksctl zaten kurulu, atlaniyor."
fi

if ! command -v helm >/dev/null 2>&1; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "helm zaten kurulu, atlaniyor."
fi

# 6. Terraform
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform

# 7. Maven ve Ansible
sudo dnf install -y maven ansible --allowerasing

# 8. Docker Kurulumu
sudo dnf install -y docker
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins
sudo systemctl enable --now docker
sudo chmod 777 /var/run/docker.sock

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 9. SonarQube (Docker)
sleep 5
if sudo docker ps -a --format '{{.Names}}' | grep -qx sonar; then
  echo "SonarQube container zaten var, baslatiliyor..."
  sudo docker start sonar
else
  sudo docker run -d --name sonar -p 9000:9000 --restart unless-stopped sonarqube:latest
fi

# 10. TRIVY
if ! command -v trivy >/dev/null 2>&1; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
else
  echo "trivy zaten kurulu, atlaniyor."
fi

# 11. Database Kurulumları
sudo dnf install -y mariadb105-server
sudo systemctl enable --now mariadb

sudo dnf install -y postgresql16-server postgresql16
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
  sudo postgresql-setup --initdb
fi
sudo systemctl enable --now postgresql

# 12. AWS CLI v2
if ! command -v aws >/dev/null 2>&1; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws
else
  echo "aws cli zaten kurulu, atlaniyor."
fi

echo "✅ KURULUM TAMAMLANDI!"
