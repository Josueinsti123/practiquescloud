variable "aws_region" {
  description = "Regió d'AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom del projecte (s'utilitza als tags)"
  type        = string
  default     = "practiquescloud"
}

variable "vpc_cidr" {
  description = "Bloc d'adreces de la VPC-03"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR de la Public Subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_a_az" {
  description = "Zona de disponibilitat de la Public Subnet A"
  type        = string
  default     = "us-east-1a"
}

variable "subnet_b_cidr" {
  description = "CIDR de la Public Subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_b_az" {
  description = "Zona de disponibilitat de la Public Subnet B"
  type        = string
  default     = "us-east-1b"
}

variable "instance_type" {
  description = "Tipus d'instància EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nom del parell de claus (key pair) a AWS"
  type        = string
  default     = "vockey"
}
