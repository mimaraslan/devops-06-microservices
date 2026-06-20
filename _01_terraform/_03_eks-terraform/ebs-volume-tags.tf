# =============================================================================
# EBS Volume Etiketleme
# Amac: AWS konsolunda diskleri anlamli isimlerle gormek (postgres-data vb.)
# Not: Mevcut node'lara apply sonrasi etiket ekler; node replace gerekmez.
# =============================================================================

# Calisan EKS worker EC2 instance'larini bul
data "aws_instances" "eks_workers" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }
}

data "aws_instance" "eks_worker" {
  for_each    = toset(data.aws_instances.eks_workers.ids)
  instance_id = each.value
}

resource "aws_ec2_tag" "eks_worker_root_volume" {
  for_each = {
    for id, inst in data.aws_instance.eks_worker :
    id => one(inst.root_block_device).volume_id
  }

  resource_id = each.value
  key         = "Name"
  value       = var.worker_root_volume_name
}

# Yalnizca worker'a bagli (in-use) postgres volume'e Name tag — Available yetim diskler ayni isimle gorunmez
data "aws_ebs_volumes" "postgres_data_attached" {
  filter {
    name   = "tag:kubernetes.io/created-for/pvc/name"
    values = ["postgres-data"]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned"]
  }

  filter {
    name   = "attachment.status"
    values = ["attached"]
  }
}

resource "aws_ec2_tag" "postgres_data_volume" {
  for_each = toset(data.aws_ebs_volumes.postgres_data_attached.ids)

  resource_id = each.value
  key         = "Name"
  value       = var.postgres_volume_name
}

# EKS node group tags Name'i EC2 instance'a iletmiyor; mevcut node'lari dogrudan etiketle
resource "aws_ec2_tag" "eks_worker_instance_name" {
  for_each = toset(data.aws_instances.eks_workers.ids)

  resource_id = each.value
  key         = "Name"
  value       = var.instance_name
}

# Yeni scale-up node'lari icin ASG uzerinden launch aninda Name tag'i
# for_each anahtari statik (node group adi); ASG adi apply sirasinda cozulur — plan hatasi olmaz
data "aws_autoscaling_groups" "eks_node_group" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [var.node_group_name]
  }

  depends_on = [aws_eks_node_group.node-grp]
}

resource "aws_autoscaling_group_tag" "eks_worker_instance_name" {
  for_each = {
    (var.node_group_name) = var.instance_name
  }

  autoscaling_group_name = one(data.aws_autoscaling_groups.eks_node_group.names)

  tag {
    key                 = "Name"
    value               = each.value
    propagate_at_launch = true
  }
}
