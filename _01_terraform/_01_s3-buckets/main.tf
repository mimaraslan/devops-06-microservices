# =============================================================================
# Modul: _01_s3-buckets
# Amac  : Terraform state ve proje dosyalari icin S3 bucket'lari olusturur.
# Siralama: Bu modul diger modullerden ONCE calistirilmalidir (backend bucket).
# Calistirma: terraform init && terraform apply  (Windows / macOS)
# =============================================================================

provider "aws" {
  region = "us-east-1"
}

# Bucket 1: EC2 modulunun Terraform state dosyasini saklar (ec2/terraform.tfstate)
resource "aws_s3_bucket" "bucket1" {
  bucket        = "my-devops-lab-bucket-1"
  force_destroy = true # destroy ile bucket ve icindeki state silinir

  tags = {
    Name        = "my-devops-lab-bucket-1"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "bucket1_versioning" {
  bucket = aws_s3_bucket.bucket1.id
  versioning_configuration {
    status = "Enabled" # State dosyasi geri alinabilir
  }
}

# Bucket 2: EKS ve ECR modullerinin state dosyalarini saklar
resource "aws_s3_bucket" "bucket2" {
  bucket        = "my-devops-lab-bucket-2"
  force_destroy = true

  tags = {
    Name        = "my-devops-lab-bucket-2"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "bucket2_versioning" {
  bucket = aws_s3_bucket.bucket2.id
  versioning_configuration {
    status = "Enabled"
  }
}


