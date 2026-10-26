###############################################################################
# Pt1.4 - Exercici 1: Primeres instàncies EC2 amb Terraform
#
# Crea 2 instàncies EC2 t3.micro amb Amazon Linux 2023 a la regió us-east-1
# dins de la VPC per defecte del compte.
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
      Exercise    = "Ex1"
      ManagedBy   = "Terraform"
      Environment = "Docent"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "Regió d'AWS on es despleguen els recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom del projecte (s'utilitza als tags i als noms dels recursos)"
  type        = string
  default     = "practiquescloud"
}

variable "instance_type" {
  description = "Tipus d'instància EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Nombre d'instàncies EC2 a crear"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0
    error_message = "Cal crear com a mínim una instància EC2."
  }
}

variable "availability_zone" {
  description = "Zona de disponibilitat de la subxarxa per defecte on es creen les instàncies"
  type        = string
  default     = "us-east-1a"
}

variable "ssh_cidr" {
  description = "CIDR autoritzat a connectar-se per SSH (millor restringir-ho a la IP pròpia)"
  type        = string
  default     = "0.0.0.0/0"
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
# Xarxa: VPC per defecte del compte (l'exercici no demana VPC pròpia)
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

# ---------------------------------------------------------------------------
# Grup de seguretat (SSH + ICMP)
# ---------------------------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-pt1-4-ex1-sg"
  description = "Acces SSH i ICMP per a les instancies de l'exercici 1"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "${var.project_name}-pt1-4-ex1-sg"
  }
}

# ---------------------------------------------------------------------------
# Instàncies EC2
# ---------------------------------------------------------------------------
resource "aws_instance" "web" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.selected.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Servidor web mínim per poder comprovar que la instància és accessible
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>Pt1.4 Exercici 1 - EC2 ${count.index + 1} (${var.instance_type})</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOF

  tags = {
    Name = "${var.project_name}-pt1-4-ex1-ec2-${count.index + 1}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "region" {
  description = "Regió on s'ha desplegat la infraestructura"
  value       = var.aws_region
}

output "ami_id" {
  description = "AMI d'Amazon Linux 2023 utilitzada"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "instance_ids" {
  description = "IDs de les instàncies EC2 creades"
  value       = aws_instance.web[*].id
}

output "public_ips" {
  description = "IPs públiques de les instàncies"
  value       = aws_instance.web[*].public_ip
}

output "private_ips" {
  description = "IPs privades de les instàncies"
  value       = aws_instance.web[*].private_ip
}
