# S3 bucket isimleri ve ortam etiketi (istege bagli ozellestirme)

variable "bucket1_name" {
  description = "Birinci S3 bucket adi (EC2 state backend)"
  type        = string
  default     = "my-devops-lab-bucket-1"
}

variable "bucket2_name" {
  description = "Ikinci S3 bucket adi (EKS/ECR state backend)"
  type        = string
  default     = "my-devops-lab-bucket-2"
}

variable "environment" {
  description = "Bucket'lara eklenecek Environment etiketi"
  type        = string
  default     = "dev"
}
