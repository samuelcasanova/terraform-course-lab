# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach S3 Full Access Policy (for lab purposes, should be restricted in production)
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Generate a static token for Kubernetes API access
resource "random_password" "k8s_token" {
  length  = 32
  special = false
}

# EC2 Instance
resource "aws_instance" "k3s_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.deployer.key_name

  # Allow replacement when user_data changes
  user_data_replace_on_change = true

  # k3s installation via user_data with static token injection
  user_data = <<-EOF
              #!/bin/bash
              # Create Swap file
              fallocate -l 2G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab

              # Create K3s config directory
              mkdir -p /var/lib/rancher/k3s/server/

              # Create static token file for API authentication
              # Format: token,user,uid,"group1,group2"
              echo "${random_password.k8s_token.result},admin,admin,\"system:masters\"" > /var/lib/rancher/k3s/server/static-tokens.csv

              # Fetch own public IP from IMDSv2
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)

              # Install k3s with the static token file flag and the dynamically fetched IP for TLS
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable metrics-server --kube-apiserver-arg=token-auth-file=/var/lib/rancher/k3s/server/static-tokens.csv --tls-san=$PUBLIC_IP" sh -
              EOF

  tags = {
    Name = "${var.project_name}-k3s-node"
  }
}

