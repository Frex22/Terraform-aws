# VPC Module Outputs

#################
# VPC
#################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}

output "default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.main.default_route_table_id
}

#################
# Internet Gateway
#################

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].id : null
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = length(aws_internet_gateway.main) > 0 ? aws_internet_gateway.main[0].arn : null
}

#################
# Subnets
#################

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# Combined subnet outputs for convenience
output "subnet_ids" {
  description = "All subnet IDs"
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
  }
}

#################
# NAT Gateways
#################

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "elastic_ip_ids" {
  description = "IDs of the Elastic IPs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

#################
# Route Tables
#################

output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

# Combined route table outputs
output "route_table_ids" {
  description = "All route table IDs"
  value = {
    public  = aws_route_table.public[*].id
    private = aws_route_table.private[*].id
  }
}

#################
# Availability Zones
#################

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

#################
# Configuration
#################

output "name" {
  description = "Name prefix used for resources"
  value       = var.name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
