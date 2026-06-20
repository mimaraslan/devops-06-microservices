# Ortak veri kaynaklari ve yerel dosya yollari

data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id

  # SSH anahtari: _01_terraform/My-Key-Linux-Amazon.pem
  # path.module sayesinde Windows ve macOS'ta ayni yol cozulur
  ssh_private_key_file = coalesce(var.ssh_private_key_path, abspath("${path.module}/../My-Key-Linux-Amazon.pem"))

  # EC2'ye kopyalanacak kurulum scripti (Amazon Linux uzerinde calisir)
  install_tools_script = "${path.module}/install-tools.sh"
}
