# Security Groups Module Variables

#################
# Required Variables
#################

variable "name_prefix" {
  description = "Name prefix for all security groups"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

#################
# Network Access Configuration
#################

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = []
}

variable "ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed SSH access"
  type        = list(string)
  default     = []
}

#################
# Application Configuration
#################

variable "app_port" {
  description = "Custom application port (if different from 80/443)"
  type        = number
  default     = null
}

variable "enable_ssh_access" {
  description = "Enable SSH access to application servers"
  type        = bool
  default     = false
}

#################
# Database Configuration
#################

variable "database_port" {
  description = "Custom database port (if different from standard ports)"
  type        = number
  default     = null
}

#################
# Optional Security Groups
#################

variable "create_alb_security_group" {
  description = "Create security group for Application Load Balancer"
  type        = bool
  default     = false
}

variable "create_eks_security_group" {
  description = "Create additional security group for EKS"
  type        = bool
  default     = false
}

#################
# Tagging
#################

variable "tags" {
  description = "Additional tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
