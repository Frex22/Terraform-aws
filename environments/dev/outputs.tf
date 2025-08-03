# Development Environment Outputs

#################
# VPC Outputs
#################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

#################
# Security Group Outputs
#################

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security_groups.app_security_group_id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = module.security_groups.database_security_group_id
}

#################
# Database Outputs
#################

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.port
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "database_username" {
  description = "Database username"
  value       = module.database.username
}

# Note: Never output passwords
# output "database_password" {
#   description = "Database password"
#   value       = module.database.password
#   sensitive   = true
# }

#################
# EKS Outputs (conditional)
#################

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = var.enable_eks ? module.eks[0].cluster_id : null
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

#################
# Environment Info
#################

output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}
