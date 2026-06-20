# Instance Profile: EC2'nin IAM role'u kullanabilmesi icin gerekli arac
# Role (mydemo-iam-role1) <-> EC2 (mydemo-server) arasindaki kopru

resource "aws_iam_instance_profile" "instance-profile" {
  name = var.iam_instance_profile_name
  role = aws_iam_role.iam-role.name
}
