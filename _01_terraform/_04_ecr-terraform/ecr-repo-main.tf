# =============================================================================
# Modul: _04_ecr-terraform
# Amac  : Microservice Docker imajlari icin ECR repository'leri olusturur.
# State : S3 backend — my-devops-lab-bucket-2 / ecr/terraform.tfstate
# Onkosul: _01_s3-buckets ve Jenkins EC2 (docker login icin)
# =============================================================================

provider "aws" {
  region = "us-east-1"  # Change as needed
}

# Jenkins pipeline'larinin push edecegi 7 microservice reposu
locals {
  services = [
    "accountservice",
    "apigatewayservice",
    "configserverlocal",
    "dashboardeurekaserver",
    "fraudservice",
    "ledgerservice",
    "notificationservice"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name = each.value

  image_scanning_configuration {
    scan_on_push = true # Push sonrasi guvenlik taramasi
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # ✅ This line tells AWS to delete all images before deleting the repo
  force_delete = true # destroy ile repodaki tum imajlar silinir 

  tags = {
    Environment = "production"
    Service     = each.value
  }
}
