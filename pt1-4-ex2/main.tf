###############################################################################
# Pt1.4 - Exercici 2: VPC, subxarxes i 6 instàncies EC2 amb Terraform
#
# Desplega:
#   - 1 VPC 10.0.0.0/16
#   - 3 subxarxes públiques a us-east-1a:
#       Subnet A -> 10.0.32.0/25
#       Subnet B -> 10.0.30.0/23
#       Subnet C -> 10.0.33.0/28
#   - 2 instàncies t3.micro (Amazon Linux 2023) per subxarxa = 6 instàncies
#   - Internet Gateway, taula de rutes i grup de seguretat
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
      Practice    = "Pt1.4"
      Exercise    = "Ex2"
      ManagedBy   = "Terraform"
      Environment = "Docent"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------








# ---------------------------------------------------------------------------
# AMI: Amazon Linux 2023
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
    Name = "vpc"
  }
}

# ---------------------------------------------------------------------------
# Subxarxes (3, totes a la mateixa AZ)
# ---------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-${each.key}"
    Tier = "public"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway + taula de rutes pública
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-pt1-4-ex2-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-pt1-4-ex2-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Grup de seguretat
# ---------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "sg"
  description = "SSH, HTTP i ICMP per a les 6 instancies de l exercici 2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "ICMP (ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.ssh_cidr]
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
# Mapa d'instàncies: 2 per subxarxa => 6 en total
# ---------------------------------------------------------------------------
locals {
  instances = merge([
    for subnet_key, subnet in var.public_subnets : {
      for idx in range(var.instances_per_subnet) :
      "${subnet_key}-${idx + 1}" => {
        subnet_key = subnet_key
        number     = idx + 1
      }
    }
  ]...)
}

resource "aws_instance" "web" {
  for_each = local.instances

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[each.value.subnet_key].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>Pt1.4 Ex2 - Subnet ${each.value.subnet_key} - EC2 ${each.value.number}</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOF

  tags = {
    Name   = "${each.value.subnet_key}-ec2-${each.value.number}"
    Subnet = each.value.subnet_key
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "Adreçament de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnets" {
  description = "Subxarxes creades (nom, ID, CIDR i AZ)"
  value = {
    for key, subnet in aws_subnet.public : key => {
      id         = subnet.id
      cidr_block = subnet.cidr_block
      az         = subnet.availability_zone
    }
  }
}

output "instance_ids" {
  description = "IDs de les 6 instàncies EC2"
  value       = { for key, instance in aws_instance.web : key => instance.id }
}

output "instance_public_ips" {
  description = "IPs públiques de les 6 instàncies EC2"
  value       = { for key, instance in aws_instance.web : key => instance.public_ip }
}

output "instance_summary" {
  description = "Resum de les instàncies desplegades"
  value = [
    for key, instance in aws_instance.web : {
      name       = instance.tags["Name"]
      subnet_key = local.instances[key].subnet_key
      subnet_id  = instance.subnet_id
      private_ip = instance.private_ip
      public_ip  = instance.public_ip
    }
  ]
}
