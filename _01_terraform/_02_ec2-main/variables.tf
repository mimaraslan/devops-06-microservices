# =============================================================================
# Degiskenler — _02_ec2-main modulu
# Varsayilan degerler egitim ortami icin ayarlanmistir.
# Ozellestirme: terraform.tfvars dosyasi olusturun (ornek: terraform.tfvars.example)
# =============================================================================

variable "region" {
  description = "AWS region bolge"
  type        = string
  default     = "us-east-1"
}

variable "vpc-name" {
  description = "VPC adi (EKS modulu bu etiketle VPC'yi bulur)"
  type        = string
  default     = "mydemo-vpc"
}

variable "igw-name" {
  description = "Internet Gateway adi"
  type        = string
  default     = "mydemo-igw"
}

variable "subnet-name1" {
  description = "Public Subnet 1 adi (EC2 buraya kurulur)"
  type        = string
  default     = "Public-Subnet-1"
}

variable "subnet-name2" {
  description = "Public Subnet 2 adi mydemo server icin"
  type        = string
  default     = "Public-subnet2"
}

# Private subnet name variables
variable "private_subnet_name1" {
  description = "Private Subnet 1 adi"
  type        = string
  default     = "Private-subnet1"
}

variable "private_subnet_name2" {
  description = "Private Subnet 2 adi"
  type        = string
  default     = "Private-subnet2"
}

variable "rt-name" {
  description = "Public route table adi mydemo server icin"
  type        = string
  default     = "mydemo-rt"
}

variable "sg-name" {
  description = "Security Group adi mydemo server icin"
  type        = string
  default     = "mydemo-sg"
}

variable "iam-role" {
  description = "IAM Role for the mydemo Server"
  type = string
  default = "mydemo-iam-role1"
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
  default     = "ami-0521cb2d60cfbb1a6"
  // Replace with the latest AMI ID for your region
  // (Amazon Linux 2023 — bolgeye gore guncelleyin)
}

variable "instance_type" {
  description = "Jenkins EC2 instance tipi"
  type        = string
  default     = "t3.xlarge"
}

variable "key_name" {
  description = "AWS EC2 keypair adi (PEM dosyasiyla eslesmeli)"
  type        = string
  default     = "My-Key-Linux-Amazon"
}

variable "instance_name" {
  description = "EC2 instance Name etiketi mydemo server icin"
  type        = string
  default     = "mydemo-server"
}

variable "root_volume_name" {
  description = "Jenkins EC2 root EBS volume Name tag'i"
  type        = string
  default     = "mydemo-jenkins-root"
}

variable "allowed_cidr_blocks" {
  description = "SG'ye izin verilen IPv4 CIDR listesi (tek IP: x.x.x.x/32)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ipv6_cidr_blocks" {
  description = "SG'ye izin verilen IPv6 CIDR listesi"
  type        = list(string)
  default     = ["::/0"]
}

variable "auto_detect_public_ip" {
  description = "true: sadece sizin guncel public IP'nize izin verilir"
  type        = bool
  default     = false
}

variable "iam_instance_profile_name" {
  description = "EC2 instance profile adi (Jenkins EC2)"
  type        = string
  default     = "mydemo-profile"
}

variable "ssh_private_key_path" {
  description = "EC2 SSH private key. Bos birakilirsa _01_terraform/My-Key-Linux-Amazon.pem kullanilir. Mutlak yol da verilebilir."
  type        = string
  default     = null
}
