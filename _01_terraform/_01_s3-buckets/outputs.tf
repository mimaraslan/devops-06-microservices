# Olusturulan bucket ID'leri — diger modullerin backend yapilandirmasinda kullanilir

output "bucket1_id" {
  description = "EC2 state backend bucket ID 1"
  value       = aws_s3_bucket.bucket1.id
}

output "bucket2_id" {
  description = "EKS/ECR state backend bucket ID 2"
  value       = aws_s3_bucket.bucket2.id
}
