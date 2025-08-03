# Module Development Guidelines

## Module Design Principles

### 1. Single Responsibility Principle
Each module should have a single, well-defined purpose:
- **VPC Module**: Create VPC, subnets, route tables, gateways
- **RDS Module**: Create database instances, subnet groups, parameter groups
- **EKS Module**: Create EKS cluster, node groups, RBAC
- **Security Group Module**: Create security groups and rules

### 2. Composition Over Inheritance
Build complex infrastructure by composing simple modules:

```hcl
# Good: Compose modules
module "vpc" {
  source = "./modules/vpc"
  # ...
}

module "database" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  # ...
}

module "kubernetes" {
  source = "./modules/eks"
  vpc_id    = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  # ...
}
```

### 3. Configuration vs. Implementation
Separate what (configuration) from how (implementation):

```hcl
# Module should accept configuration
module "database" {
  source = "./modules/rds"
  
  # What we want
  engine_version = "13.7"
  instance_class = "db.t3.micro"
  storage_size   = 20
  
  # Not how to implement it
  # parameter_group_name = "custom-pg-13"  # Module should handle this
}
```

## Module Structure

### Standard Module Layout:

```
modules/vpc/
├── main.tf          # Primary resources
├── variables.tf     # Input variables  
├── outputs.tf       # Output values
├── versions.tf      # Provider requirements
├── locals.tf        # Local values (optional)
├── data.tf          # Data sources (optional)
├── README.md        # Documentation
└── examples/        # Usage examples
    └── complete/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### File Purposes:

#### main.tf
- Primary resource definitions
- Core functionality of the module
- Resource relationships and dependencies

#### variables.tf
- All input variable declarations
- Variable descriptions and types
- Default values where appropriate
- Validation rules

#### outputs.tf
- All output value declarations
- Output descriptions
- Sensitive output markings

#### versions.tf
- Terraform version constraints
- Provider version requirements
- Provider configuration (if needed)

## Variable Design

### 1. Variable Types and Validation

```hcl
# String variables with validation
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Number variables with constraints
variable "min_capacity" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_capacity >= 1 && var.min_capacity <= 100
    error_message = "Minimum capacity must be between 1 and 100."
  }
}

# Complex object variables
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    storage_size   = number
    storage_type   = string
  })
  
  default = {
    engine         = "postgres"
    engine_version = "13.7"
    instance_class = "db.t3.micro"
    storage_size   = 20
    storage_type   = "gp2"
  }
}

# Map variables for flexibility
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# List variables
variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = []
}
```

### 2. Variable Organization

Group variables logically in variables.tf:

```hcl
#################
# Required Inputs
#################

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

#################
# Optional Inputs
#################

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

#################
# Networking
#################

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = []
}

#################
# Security
#################

variable "allowed_security_groups" {
  description = "Security groups allowed to access"
  type        = list(string)
  default     = []
}

#################
# Tagging
#################

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

## Output Design

### 1. Comprehensive Outputs

```hcl
# Resource IDs (most important)
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of all subnets"
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
  }
}

# Resource ARNs (for cross-service integration)
output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Configuration values (for dependent resources)
output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

# Security-related outputs
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}

# Sensitive outputs
output "database_password" {
  description = "Generated database password"
  value       = random_password.database.result
  sensitive   = true
}
```

### 2. Output Organization

Group outputs logically:

```hcl
#################
# VPC
#################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

#################
# Subnets
#################

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

#################
# Security
#################

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}
```

## Module Examples

### 1. VPC Module Structure

```hcl
# modules/vpc/main.tf
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  
  common_tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public-${count.index + 1}"
      Type = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-${count.index + 1}"
      Type = "private"
    }
  )
}

resource "aws_internet_gateway" "main" {
  count = length(var.public_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}
```

### 2. RDS Module Structure

```hcl
# modules/rds/main.tf
locals {
  common_tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "main" {
  count = var.create_parameter_group ? 1 : 0

  family = var.parameter_group_family
  name   = "${var.name}-params"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.common_tags
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name}-database-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-database-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  identifier = var.name

  # Engine settings
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage settings
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database settings
  db_name  = var.database_name
  username = var.username
  password = var.password

  # Network settings
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = var.publicly_accessible
  port                   = var.port

  # Parameter group
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.main[0].name : var.parameter_group_name

  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval

  # Lifecycle
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"
  deletion_protection       = var.deletion_protection

  tags = local.common_tags
}
```

## Module Documentation

### README.md Template:

```markdown
# [Module Name] Module

Brief description of what this module does.

## Usage

### Basic Example

```hcl
module "example" {
  source = "./modules/[module-name]"

  name        = "my-project"
  environment = "dev"
  
  # Required parameters
  vpc_id = "vpc-12345678"
  
  # Optional parameters
  enable_feature = true
}
```

### Complete Example

```hcl
module "example" {
  source = "./modules/[module-name]"

  name        = "my-project"
  environment = "prod"
  
  # All available options
  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  enable_feature     = true
  instance_count     = 3
  
  tags = {
    Project = "MyProject"
    Owner   = "team@company.com"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_resource.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name prefix for resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_enable_feature"></a> [enable\_feature](#input\_enable\_feature) | Enable specific feature | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | ID of the created resource |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the created resource |
```

## Testing Modules

### 1. Example Configurations

Create example configurations in `examples/` directory:

```
modules/vpc/examples/
├── complete/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── simple/
    ├── main.tf
    └── README.md
```

### 2. Automated Testing

Use tools like Terratest for automated testing:

```go
// test/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

This comprehensive guide covers module development from design principles to implementation details. Following these guidelines will help you create reusable, maintainable, and well-documented Terraform modules.
