# AWS Region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Project Name
variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "terraform-aws-vm"
}

# Environment
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnet CIDR
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Private Subnet CIDR
variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# SSH Public Key Path
variable "public_key_path" {
  description = "Path to the SSH public key for EC2 access"
  type        = string
  default     = "~/.ssh/terraform-aws-key.pub"
}