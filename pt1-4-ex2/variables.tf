variable "aws_region" {
  description = "Regió d'AWS"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Zona de disponibilitat on es creen les 3 subxarxes"
  type        = string
  default     = "us-east-1a"
}

variable "project_name" {
  description = "Nom del projecte"
  type        = string
  default     = "practiquescloud"
}

variable "vpc_cidr" {
  description = "Adreçament de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Tipus d'instància EC2"
  type        = string
  default     = "t3.micro"
}

variable "instances_per_subnet" {
  description = "Nombre d'instàncies EC2 per cada subxarxa"
  type        = number
  default     = 2
}

variable "ssh_cidr" {
  description = "CIDR autoritzat a connectar-se per SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "public_subnets" {
  description = "Subxarxes públiques de la VPC (clau = nom, valor = CIDR)"
  type = map(object({
    cidr_block = string
    az         = string
  }))

  default = {
    A = { cidr_block = "10.0.32.0/25", az = "us-east-1a" }
    B = { cidr_block = "10.0.30.0/23", az = "us-east-1a" }
    C = { cidr_block = "10.0.33.0/28", az = "us-east-1a" }
  }

  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "L'enunciat demana exactament 3 subxarxes."
  }
}
