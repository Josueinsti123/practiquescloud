###############################################################################
# Pt2.2 — Infraestructura bàsica a AWS amb Terraform
#
# VPC-03 (10.0.0.0/16) amb 2 subxarxes públiques (us-east-1a i us-east-1b),
# Internet Gateway, taula de rutes, Security Group i 2 instàncies EC2 t3.micro.
#
# Ús:
#   terraform init
#   terraform plan
#   terraform apply -auto-approve
#   terraform destroy -auto-approve
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Practice    = "Pt2.2"
      ManagedBy   = "Terraform"
      Environment = "Docent"
    }
  }
}

# ---------------------------------------------------------------------------
# AMI: Amazon Linux 2023 (x86_64) - sempre la més recent
# ---------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-03"
  }
}

# ---------------------------------------------------------------------------
# Subxarxes públiques (2, en AZ diferents)
# ---------------------------------------------------------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.subnet_a_az
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.subnet_b_az
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet B"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway + taula de rutes pública
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Grup de seguretat
#   - SSH des de qualsevol lloc (0.0.0.0/0)
#   - ICMP només des de dins de la VPC (10.0.0.0/16)
#   - Tot el trànsit sortint permès
# ---------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "sg"
  description = "SSH des de qualsevol lloc, ICMP des de la VPC, egress total"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP des de la VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Sortida a Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}

# ---------------------------------------------------------------------------
# Instàncies EC2 (una per subxarxa)
# ---------------------------------------------------------------------------
resource "aws_instance" "ec2_a" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name

  tags = {
    Name = "ec2-a"
  }
}

resource "aws_instance" "ec2_b" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_b.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name

  tags = {
    Name = "ec2-b"
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID de la VPC-03"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_a_id" {
  description = "ID de la Public Subnet A"
  value       = aws_subnet.public_a.id
}

output "subnet_b_id" {
  description = "ID de la Public Subnet B"
  value       = aws_subnet.public_b.id
}

output "instance_a_id" {
  description = "ID de l'instància ec2-a"
  value       = aws_instance.ec2_a.id
}

output "instance_b_id" {
  description = "ID de l'instància ec2-b"
  value       = aws_instance.ec2_b.id
}

output "instance_a_public_ip" {
  description = "IP pública de ec2-a"
  value       = aws_instance.ec2_a.public_ip
}

output "instance_b_public_ip" {
  description = "IP pública de ec2-b"
  value       = aws_instance.ec2_b.public_ip
}
