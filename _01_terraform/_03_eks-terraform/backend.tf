# =============================================================================
# Modul: _03_eks-terraform — Terraform ve provider yapilandirmasi
# State : S3 backend — my-devops-lab-bucket-2 / k8/terraform.tfstate
# Onkosul: _02_ec2-main (VPC, SG) uygulanmis olmali
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0" # OIDC provider thumbprint icin
    }
  }

  backend "s3" {
    bucket = "my-devops-lab-bucket-2"
    key    = "k8/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 1.6.3"
}
