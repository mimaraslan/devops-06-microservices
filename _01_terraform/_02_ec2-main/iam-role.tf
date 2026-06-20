# -----------------------------------------------------------------------------
# IAM Role: mydemo-iam-role1
# Jenkins EC2 makinesinin AWS API'lerine erismesi icin kullanilir.
# terraform apply ile olusturulur, destroy ile silinir.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "iam-role" {
  name                  = var.iam-role
  force_detach_policies = true # destroy sirasinda policy baglantilarini otomatik koparir
  assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
