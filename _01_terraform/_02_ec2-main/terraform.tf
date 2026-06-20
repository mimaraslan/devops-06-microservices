# =============================================================================
# Modul: _02_ec2-main
# Amac  : Jenkins CI/CD sunucusu (EC2), VPC, IAM role ve Elastic IP kurar.
# State : S3 backend — my-devops-lab-bucket-1 / ec2/terraform.tfstate
# Calistirma: apply-ec2.ps1 (Windows) veya apply-ec2.sh (macOS/Linux)
# Onkosul : _01_s3-buckets modulu uygulanmis olmali
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0" # auto_detect_public_ip icin public IP sorgusu
    }
  }

  backend "s3" {
    bucket = "my-devops-lab-bucket-1"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.6.3"
}

provider "aws" {
  region = "us-east-1"
}
