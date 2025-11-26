# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# VPC CIDR Block
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Public Subnet ID
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

# Private Subnet ID
output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# Internet Gateway ID
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Security Group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server.id
}

# EC2 Instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

# EC2 Instance Public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

# EC2 Instance Private IP
output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

# EC2 Instance Public DNS
output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

# SSH Connection Command
output "ssh_connection_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ~/.ssh/terraform-aws-key ubuntu@${aws_instance.web_server.public_ip}"
}

# Web URL
output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}