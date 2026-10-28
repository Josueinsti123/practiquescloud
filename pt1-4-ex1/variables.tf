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
  description = "CIDR autoritzat a connectar-se a les instàncies (SSH, HTTP i ICMP). Millor restringir-ho a la IP pròpia"
  type        = string
  default     = "0.0.0.0/0"
}
