# -----------------------------------------------------------------------------
# EC2 Jenkins Sunucusu + Kurulum Provisioner + Elastic IP
# -----------------------------------------------------------------------------

resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public-subnet1.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name

  root_block_device {
    volume_size = 30
    tags = {
      Name        = var.root_volume_name
      Environment = "dev"
      Terraform   = "true"
    }
  }

  # Kurulum install-tools.sh ile yapilir (user_data kullanilmiyor — cift kurulum onlenir)
  tags = {
    Name = var.instance_name
  }
}

# Terraform SSH ile EC2'ye baglanip install-tools.sh calistirir
# Script degisirse veya EC2 yeniden olusursa bu blok tekrar calisir
resource "null_resource" "provisioner" {
  triggers = {
    script_hash = filemd5(local.install_tools_script)
    instance_id = aws_instance.ec2.id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(local.ssh_private_key_file)
    host        = aws_eip.mydemo_eip.public_ip
  }

  provisioner "file" {
    source      = local.install_tools_script
    destination = "/tmp/install-tools.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-tools.sh",
      "sudo /tmp/install-tools.sh"
    ]
  }

  depends_on = [aws_eip_association.mydemo_eip_assoc]
}

# Sabit public IP — Jenkins URL'si destroy sonrasi bile ayni kalabilir (yeniden apply)
resource "aws_eip" "mydemo_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.instance_name}-eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip_association" "mydemo_eip_assoc" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.mydemo_eip.id
}
