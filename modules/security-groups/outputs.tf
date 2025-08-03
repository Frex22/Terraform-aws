# Security Groups Module Outputs

#################
# Application Security Group
#################

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "app_security_group_arn" {
  description = "ARN of the application security group"
  value       = aws_security_group.app.arn
}

output "app_security_group_name" {
  description = "Name of the application security group"
  value       = aws_security_group.app.name
}

#################
# Database Security Group
#################

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.database.arn
}

output "database_security_group_name" {
  description = "Name of the database security group"
  value       = aws_security_group.database.name
}

#################
# Load Balancer Security Group
#################

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.create_alb_security_group ? aws_security_group.alb[0].id : null
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = var.create_alb_security_group ? aws_security_group.alb[0].arn : null
}

output "alb_security_group_name" {
  description = "Name of the ALB security group"
  value       = var.create_alb_security_group ? aws_security_group.alb[0].name : null
}

#################
# EKS Security Group
#################

output "eks_security_group_id" {
  description = "ID of the EKS additional security group"
  value       = var.create_eks_security_group ? aws_security_group.eks_additional[0].id : null
}

output "eks_security_group_arn" {
  description = "ARN of the EKS additional security group"
  value       = var.create_eks_security_group ? aws_security_group.eks_additional[0].arn : null
}

output "eks_security_group_name" {
  description = "Name of the EKS additional security group"
  value       = var.create_eks_security_group ? aws_security_group.eks_additional[0].name : null
}

#################
# All Security Groups (for convenience)
#################

output "all_security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    app      = aws_security_group.app.id
    database = aws_security_group.database.id
    alb      = var.create_alb_security_group ? aws_security_group.alb[0].id : null
    eks      = var.create_eks_security_group ? aws_security_group.eks_additional[0].id : null
  }
}
