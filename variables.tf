variable "region" {
  default     = "us-east-1"
  description = "The region to use for all resources"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "The CIDR block for the VPC"
}

variable "public_subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "The CIDR block for the public subnet"
}

variable "compute_subnet_cidr" {
  default     = "10.0.2.0/24"
  description = "The CIDR block for the compute subnet"
}

variable "database_subnet_cidr" {
  default     = "10.0.3.0/24"
  description = "The CIDR block for the database subnet"
}
