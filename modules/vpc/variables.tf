# VPC Module Variables

#################
# Required Variables
#################

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

#################
# Subnet Configuration
#################

variable "availability_zones" {
  description = "List of availability zones. If empty, will use first 3 AZs in the region"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
}

#################
# VPC Configuration
#################

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

#################
# NAT Gateway Configuration
#################

variable "enable_nat_gateway" {
  description = "Enable NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = false
}

#################
# VPC Flow Logs
#################

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention for VPC flow logs"
  type        = number
  default     = 14
}

#################
# Tagging
#################

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#################
# Validation
#################

# Validate that we have the same number of private subnets and AZs (if AZs are specified)
locals {
  validate_az_count = length(var.availability_zones) == 0 || length(var.availability_zones) >= length(var.private_subnet_cidrs)
}

# You can add validation rules like this:
# variable "cidr_validation" {
#   description = "This variable is used for validation only"
#   type        = string
#   default     = ""
#   
#   validation {
#     condition     = can(cidrhost(var.cidr_block, 0))
#     error_message = "The cidr_block must be a valid IPv4 CIDR block."
#   }
# }
