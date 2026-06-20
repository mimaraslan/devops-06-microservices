# -----------------------------------------------------------------------------
# VPC ve Ag Altyapisi
# Jenkins EC2 ve (sonraki adimda) EKS cluster bu VPC uzerinde calisir.
# -----------------------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc-name
  }
}

# auto_detect_public_ip=true ise: sadece sizin guncel public IP'niz SG'ye acilir
data "http" "public_ip" {
  url = "https://api.ipify.org"
}

locals {
  detected_public_ip_cidr      = "${trimspace(data.http.public_ip.response_body)}/32"
  effective_allowed_ipv4_cidrs = var.auto_detect_public_ip ? [local.detected_public_ip_cidr] : var.allowed_cidr_blocks
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw-name
  }
}

# Public subnet'ler — EC2 ve EKS node'lari internete cikar
resource "aws_subnet" "public-subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet-name1
  }
}

resource "aws_subnet" "public-subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet-name2
  }
}

# Private subnet'ler — ileride ic servisler icin (simdilik route yok)
resource "aws_subnet" "private-subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = var.private_subnet_name1
  }
}

resource "aws_subnet" "private-subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = var.private_subnet_name2
  }
}

# Public subnet'lerin internete cikisi
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.rt-name
  }
}

resource "aws_route_table_association" "rt-association" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.public-subnet1.id
}

resource "aws_route_table_association" "rt-association2" {
  route_table_id = aws_route_table.rt.id
  subnet_id      = aws_subnet.public-subnet2.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Private-RT"
  }
}

resource "aws_route_table_association" "private_rt_association1" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private-subnet1.id
}

resource "aws_route_table_association" "private_rt_association2" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private-subnet2.id
}

# Security Group — Jenkins, SonarQube, SSH ve microservice portlari
resource "aws_security_group" "security-group" {
  vpc_id      = aws_vpc.vpc.id
  description = "Jenkins, SonarQube, SSH ve uygulama portlari"

  ingress = [
    for port in [22, 80, 443, 8080, 8180, 8761, 8888, 9000, 9090, 9411, 9999, 3306] : {
      description      = "Port ${port} erisimi"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
      self             = false
      prefix_list_ids  = []
      security_groups  = []
      cidr_blocks      = local.effective_allowed_ipv4_cidrs
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-name
  }
}
