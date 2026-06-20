# ---------------------------------------------------------
# 1. Bölge Yapılandırması
# ---------------------------------------------------------
variable "aws_region" {
  description = "Kaynakların oluşturulacağı AWS bölgesi"
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------
# 2. EKS Cluster Değişkenleri
# ---------------------------------------------------------
variable "cluster_name" {
  description = "EKS Cluster'ın adı (main.tf içindeki project-eks ile uyumlu)"
  type        = string
  default     = "project-eks"
}

# ---------------------------------------------------------
# 3. Node Group ve Makine İsimlendirme
# ---------------------------------------------------------
variable "node_group_name" {
  description = "EKS Node Group'un AWS panelindeki grup adı"
  type        = string
  default     = "project-eks-node-group"
}

variable "instance_name" {
  description = "Worker Node makinelerinin EC2 panelinde görünecek etiketi (Tag: Name)"
  type        = string
  default     = "mydemo-eks-worker-node"
}

# ---------------------------------------------------------
# 4. Node Donanım Ayarları (Opsiyonel)
# ---------------------------------------------------------
variable "instance_types" {
  description = "Worker Node'lar için kullanılacak makine tipi"
  type        = list(string)
  default     = ["t3.xlarge"]
}

variable "disk_size" {
  description = "Her bir Worker Node için disk boyutu (GB)"
  type        = number
  default     = 30
}

variable "worker_root_volume_name" {
  description = "EKS worker root EBS volume Name tag'i"
  type        = string
  default     = "project-eks-worker-root"
}

variable "postgres_volume_name" {
  description = "Postgres PVC EBS volume Name tag'i"
  type        = string
  default     = "project-eks-postgres-data"
}