output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Subnet outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "compute_subnet_id" {
  description = "ID of the compute subnet"
  value       = aws_subnet.compute.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = aws_subnet.database.id
}

output "all_subnet_ids" {
  description = "List of all subnet IDs"
  value = [
    aws_subnet.public.id,
    aws_subnet.compute.id,
    aws_subnet.database.id
  ]
}

# Route table outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "compute_route_table_id" {
  description = "ID of the compute route table"
  value       = aws_route_table.compute.id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

# NAT Gateway and EIP outputs
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP"
  value       = aws_eip.nat.id
}

# Security Group outputs
output "public_security_group_id" {
  description = "ID of the public security group"
  value       = aws_security_group.public.id
}

output "compute_security_group_id" {
  description = "ID of the compute security group"
  value       = aws_security_group.compute.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
