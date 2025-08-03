# Development Environment Variables

#################
# Global
#################

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

#################
# Networking
#################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access resources"
  type        = list(string)
  default     = [
    "0.0.0.0/0"  # Open for dev - restrict in prod
  ]
}

#################
# Database
#################

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    storage_size   = number
    database_name  = string
    username       = string
    password       = string
  })
  default = {
    engine         = "postgres"
    engine_version = "15.4"
    instance_class = "db.t3.micro"
    storage_size   = 20
    database_name  = "appdb"
    username       = "dbadmin"
    password       = "change-me-in-tfvars"  # Override in terraform.tfvars
  }
}

#################
# EKS
#################

variable "enable_eks" {
  description = "Enable EKS cluster creation"
  type        = bool
  default     = false
}

variable "eks_node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    update_config = object({
      max_unavailable = number
    })
  }))
  default = {
    general = {
      instance_types = ["t3.medium"]
      scaling_config = {
        desired_size = 2
        max_size     = 4
        min_size     = 1
      }
      update_config = {
        max_unavailable = 1
      }
    }
  }
}
