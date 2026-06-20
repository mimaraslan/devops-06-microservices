# =============================================================================
# Modul: _03_eks-terraform
# Amac  : EKS cluster, worker node group, OIDC, EBS CSI driver kurar.
# Onkosul: _02_ec2-main ile olusturulan VPC (mydemo-vpc) mevcut olmali.
# Calistirma: terraform init && terraform apply  (Windows / macOS)
# =============================================================================

provider "aws" {
  region = "us-east-1"
}

# ---------------------------------------------------------
# 1. IAM Role for EKS Cluster (Control Plane)
# ---------------------------------------------------------
# Bu rol, AWS EKS servisinin (Control Plane) senin adına 
# EC2, ELB gibi diğer AWS servislerini yönetmesini sağlar.
resource "aws_iam_role" "master" {
  name = "mydemo-eks-master1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Cluster'ın çalışması için gerekli temel AWS yönetilen politikalarını role bağlıyoruz.
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

# ---------------------------------------------------------
# 2. IAM Role for Worker Nodes
# ---------------------------------------------------------
# Bu rol, worker node'ların (EC2 makineleri) cluster'a dahil olabilmesi
# ve log gönderme, imaj çekme gibi işlemleri yapabilmesi içindir.
resource "aws_iam_role" "worker" {
  name = "mydemo-eks-worker1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Node'ların otomatik ölçeklenmesi (Autoscaling) için özel politika oluşturuyoruz.
resource "aws_iam_policy" "autoscaler" {
  name        = "mydemo-eks-autoscaler-policy1"
  description = "EKS Autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Worker Node'lar için gerekli standart AWS politikalarını bağlıyoruz.
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "S3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

# Oluşturduğumuz autoscaler politikasını worker rolüne bağlıyoruz.
resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

# EC2 makinelerinin bu rolü kullanabilmesi için instance profile oluşturuyoruz.
resource "aws_iam_instance_profile" "worker" {
  depends_on = [aws_iam_role.worker]
  name       = "mydemo-eks-worker-profile1"
  role       = aws_iam_role.worker.name
}

# ---------------------------------------------------------
# 3. VPC and Subnet Data Sources
# ---------------------------------------------------------
# Mevcut olan ağ altyapısını (VPC ve Subnetler) etiketlerine göre bulup okuyoruz.
data "aws_vpc" "main" {
  tags = {
    Name = "mydemo-vpc"
  }
}

data "aws_subnet" "subnet-1" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-1"]
  }
}

data "aws_subnet" "subnet-2" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["Public-subnet2"]
  }
}

data "aws_security_group" "selected" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["mydemo-sg"]
  }
}

# ---------------------------------------------------------
# 4. EKS Cluster
# ---------------------------------------------------------
# Kubernetes yönetim panelini (Control Plane) kuruyoruz.
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name # varsayilan: project-eks
  role_arn = aws_iam_role.master.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.subnet-1.id, data.aws_subnet.subnet-2.id]
    security_group_ids = [data.aws_security_group.selected.id]
  }

  # Yeni nesil erişim modu: Hem API üzerinden hem ConfigMap üzerinden erişim sağlar.
  # bootstrap_cluster_creator_admin_permissions: Cluster'ı kuran Jenkins'e otomatik admin yetkisi verir.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name        = "mydemo-eks-cluster"
    Environment = "dev"
    Terraform   = "true"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}

# ---------------------------------------------------------
# 5. EKS Node Group
# ---------------------------------------------------------
# Cluster üzerinde pod'ların çalışacağı gerçek EC2 makinelerini (Worker Node) kuruyoruz.
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "project-eks-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = [data.aws_subnet.subnet-1.id]
  capacity_type   = "ON_DEMAND"
  disk_size       = var.disk_size
  instance_types  = var.instance_types

  labels = {
    env = "dev"
  }

  # MyNode etiketi sayesinde EC2 panelinde makineleri bu isimle görürsün.
  # OTOMATİK İSİMLENDİRME BURADA YAPILIYOR
  tags = {
    "Name" = var.instance_name # variables.tf içindeki 'mydemo-eks-node' değerini basar
    "kubernetes.io/cluster/${aws_eks_cluster.eks.name}" = "owned"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.autoscaler,
  ]
}

# ---------------------------------------------------------
# 6. Kullanıcı ve Rol Erişimi (Access Entry)
# ---------------------------------------------------------
# 6.1. Kişisel Kullanıcı Erişimi (mydemouser)
# Senin (mydemouser) cluster'a dışarıdan bağlanabilmen için kapıyı açıyoruz.
resource "aws_eks_access_entry" "mydemouser_access" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = "arn:aws:iam::${local.aws_account_id}:user/mydemouser"
  type          = "STANDARD"
}

# 'mydemouser' kullanıcısına Cluster Admin yetkisi atıyoruz.
resource "aws_eks_access_policy_association" "mydemouser_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${local.aws_account_id}:user/mydemouser"

  access_scope {
    type = "cluster"
  }
}

# 6.2. Jenkins EC2 role erisimi (mydemo-iam-role1)
# EC2 uzerinden kubectl/eksctl calistirildiginda cluster admin yetkisi
resource "aws_eks_access_policy_association" "mydemo_terminal_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${local.aws_account_id}:role/mydemo-iam-role1"

  access_scope {
    type = "cluster"
  }
}

# ---------------------------------------------------------
# 7. OIDC Provider
# ---------------------------------------------------------
# Kubernetes içindeki servislerin (pod'ların) AWS servislerine 
# güvenli bir şekilde erişebilmesi için kimlik doğrulama altyapısı sağlar.
data "aws_eks_cluster" "eks_oidc" {
  name = aws_eks_cluster.eks.name
}

data "tls_certificate" "oidc_thumbprint" {
  url = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer
}

# ---------------------------------------------------------
# 8. EBS CSI Driver (PersistentVolume / EBS disk provisioning)
# ---------------------------------------------------------
resource "aws_iam_role" "ebs_csi_driver" {
  name = "project-eks-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.62.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.node-grp,
    aws_iam_role_policy_attachment.ebs_csi_driver,
  ]
}