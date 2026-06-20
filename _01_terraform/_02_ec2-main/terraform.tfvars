# Default: keep public access open
allowed_cidr_blocks      = ["0.0.0.0/0"]
allowed_ipv6_cidr_blocks = ["::/0"]
auto_detect_public_ip    = false

# Kendi IP numaram
# curl ifconfig.me

# To lock down only to your current public IP, replace values like:
# allowed_cidr_blocks      = ["YOUR_PUBLIC_IP/32"]
# allowed_ipv6_cidr_blocks = []
# or just set:
# auto_detect_public_ip    = true
