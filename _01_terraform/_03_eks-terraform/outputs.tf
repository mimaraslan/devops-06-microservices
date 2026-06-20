# EKS modulu ciktilari — kubectl baglantisi ve cluster bilgileri

output "cluster_name" {
  description = "EKS cluster adi (kubectl --context icin)"
  value       = aws_eks_cluster.eks.name
}

output "aws_account_id" {
  description = "AWS hesap numarasi"
  value       = local.aws_account_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.eks.arn
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_version" {
  description = "Kubernetes surumu"
  value       = aws_eks_cluster.eks.version
}

output "node_group_name" {
  description = "Managed node group adi"
  value       = aws_eks_node_group.node-grp.node_group_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (IRSA / pod IAM rolleri icin)"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "ebs_csi_driver_role_arn" {
  description = "EBS CSI driver IAM role ARN (PersistentVolume / postgres PVC)"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "kubeconfig_command" {
  description = "Yerel makinede kubectl baglantisi kurmak icin calistirin"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks.name}"
}
