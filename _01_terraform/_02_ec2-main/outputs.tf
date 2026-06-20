# Modul ciktilari — apply sonrasi terminalde gorunur (terraform output)

output "region" {
  description = "AWS bolgesi"
  value       = var.region
}

output "aws_account_id" {
  description = "AWS hesap numarasi"
  value       = local.aws_account_id
}

output "mydemo_public_ip" {
  description = "Jenkins EC2 Elastic IP — tarayicida http://<ip>:8080"
  value       = aws_eip.mydemo_eip.public_ip
}

output "compose_api_gateway_url" {
  description = "Docker Compose ile calistirildiginde API Gateway URL"
  value       = "http://${aws_eip.mydemo_eip.public_ip}"
}

output "compose_keycloak_url" {
  description = "Docker Compose ile calistirildiginde Keycloak URL"
  value       = "http://${aws_eip.mydemo_eip.public_ip}:8180"
}
