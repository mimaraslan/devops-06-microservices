# ECR ciktilari — Jenkins pipeline ve docker push icin kullanilir

output "ecr_registry_id" {
  description = "AWS hesap ID (ECR registry adresi)"
  value       = values(aws_ecr_repository.services)[0].registry_id
}

output "ecr_repository_urls" {
  description = "Her microservice icin ECR repository URL"
  value       = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}

output "ecr_repository_arns" {
  description = "Her microservice icin ECR repository ARN"
  value       = { for name, repo in aws_ecr_repository.services : name => repo.arn }
}

output "ecr_login_command" {
  description = "Jenkins/EC2'de ECR'ye docker login komutu"
  value       = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${values(aws_ecr_repository.services)[0].registry_id}.dkr.ecr.us-east-1.amazonaws.com"
}
