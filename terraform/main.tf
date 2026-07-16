# ─────────────────────────────────────────────────────────────────────────────
# Common tags applied to all resources
# ─────────────────────────────────────────────────────────────────────────────
locals {
  common_tags = {
    Project     = "efn"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Ubuntu 24.04 LTS AMI (always latest patched version)
# ─────────────────────────────────────────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Group — only HTTP/HTTPS, no SSH (SSM replaces it)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "efn" {
  name        = "efn-sg"
  description = "Allow HTTP/HTTPS inbound, all outbound"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "efn-sg" })
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM — EC2 Instance Profile (allows SSM Agent to communicate with AWS)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ec2" {
  name = "efn-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "efn-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ─────────────────────────────────────────────────────────────────────────────
# EC2 Instance
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_instance" "efn" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.efn.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(local.common_tags, { Name = "efn-server" })

  lifecycle {
    prevent_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Elastic IP (static public IP for Cloudflare DNS)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_eip" "efn" {
  instance = aws_instance.efn.id

  tags = merge(local.common_tags, { Name = "efn-eip" })

  lifecycle {
    prevent_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM — GitHub OIDC Provider
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1c587c5c6f17e546197066c1e554747386ae1377"]
}

# ─────────────────────────────────────────────────────────────────────────────
# IAM — GitHub Actions Deployment Role (OIDC + SSM permissions)
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "github_actions" {
  name = "efn-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_ssm" {
  name = "efn-ssm-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSMCommandOnEfnOnly"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          aws_instance.efn.arn,
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
        ]
      },
      {
        Sid      = "AllowSSMReadResults"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      },
      {
        Sid      = "AllowEC2Describe"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      }
    ]
  })
}
