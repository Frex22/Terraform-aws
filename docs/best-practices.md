# Terraform Best Practices

## Project Organization

### 1. Directory Structure

#### Root Level Files:
- `terraform.tf` - Terraform and provider versions
- `README.md` - Project documentation
- `.gitignore` - Git ignore rules
- `Makefile` - Common commands (optional)

#### Environment Structure:
```
environments/
├── dev/
│   ├── main.tf           # Main configuration
│   ├── variables.tf      # Variable declarations
│   ├── outputs.tf        # Output declarations
│   ├── terraform.tfvars  # Variable values
│   └── backend.tf        # Backend configuration
├── staging/
└── prod/
```

#### Module Structure:
```
modules/
├── vpc/
│   ├── main.tf           # Main resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── versions.tf       # Provider requirements
│   └── README.md         # Module documentation
```

### 2. File Naming Conventions

#### Standard Files (in order of preference):
1. `terraform.tf` or `versions.tf` - Provider and Terraform version constraints
2. `main.tf` - Primary resources
3. `variables.tf` - Variable declarations
4. `outputs.tf` - Output declarations
5. `locals.tf` - Local values
6. `data.tf` - Data sources
7. `backend.tf` - Backend configuration (environment level)

#### Additional Files:
- `terraform.tfvars` - Variable values (never commit sensitive values)
- `terraform.tfvars.example` - Example variable file (safe to commit)

## Code Organization

### 1. Resource Naming

#### Use Consistent Naming:
```hcl
# Good
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  # ...
}

# Avoid
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "my_subnet" {
  vpc_id = aws_vpc.vpc1.id
  # ...
}
```

#### Naming Convention:
- Use descriptive names
- Use underscores, not hyphens
- Be consistent across the project
- Use singular form for single resources
- Use plural form for multiple resources

### 2. Variable Organization

#### variables.tf Structure:
```hcl
# Required variables first
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Optional variables with defaults
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Complex variables
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
```

#### Variable Best Practices:
- Always include descriptions
- Use appropriate types
- Provide sensible defaults where possible
- Group related variables together
- Use validation rules when needed

### 3. Output Organization

#### outputs.tf Structure:
```hcl
# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet outputs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Sensitive outputs
output "database_password" {
  description = "RDS instance password"
  value       = aws_db_instance.database.password
  sensitive   = true
}
```

## Module Development

### 1. Module Design Principles

#### Single Responsibility:
- Each module should have one clear purpose
- Don't create "god modules" that do everything
- Prefer composition over large modules

#### Example - Good Module Design:
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-private-${count.index + 1}"
      Type = "private"
    }
  )
}
```

### 2. Module Interface Design

#### Input Variables:
```hcl
# Required inputs
variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# Optional inputs with defaults
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

# Complex inputs
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

#### Output Values:
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}
```

### 3. Module Documentation

#### README.md Template:
```markdown
# VPC Module

This module creates a VPC with public and private subnets.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix    = "my-project"
  cidr_block     = "10.0.0.0/16"
  
  private_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  
  availability_zones = [
    "us-west-2a",
    "us-west-2b"
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| cidr_block | CIDR block for VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| private_subnet_ids | IDs of the private subnets |
```

## Security Best Practices

### 1. Sensitive Data Handling

#### Never Hardcode Secrets:
```hcl
# Bad
resource "aws_db_instance" "database" {
  password = "hardcoded-password"  # Never do this!
}

# Good
resource "aws_db_instance" "database" {
  password = var.database_password
}

# Better
resource "aws_db_instance" "database" {
  manage_master_user_password = true
}
```

#### Use AWS Secrets Manager:
```hcl
resource "aws_secretsmanager_secret" "database_password" {
  name = "${var.project_name}-${var.environment}-db-password"
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = var.database_password
}
```

### 2. IAM Best Practices

#### Principle of Least Privilege:
```hcl
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Attach only necessary policies
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

## Performance and Reliability

### 1. Use Data Sources

#### Fetch Existing Resources:
```hcl
# Get existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Get latest AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### 2. Resource Dependencies

#### Explicit Dependencies:
```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private[0].id

  depends_on = [
    aws_nat_gateway.main
  ]

  tags = {
    Name = "web-server"
  }
}
```

### 3. Error Handling

#### Resource Lifecycle:
```hcl
resource "aws_instance" "database" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.large"

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      ami,  # Ignore AMI updates
    ]
  }

  tags = {
    Name = "database-server"
  }
}
```

## Testing and Validation

### 1. Variable Validation

```hcl
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of instances"
  type        = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

### 2. Pre-commit Hooks

#### .pre-commit-config.yaml:
```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.77.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
```

## Common Patterns

### 1. Local Values

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  name_prefix = "${var.project_name}-${var.environment}"
}
```

### 2. Conditional Resources

```hcl
resource "aws_cloudwatch_log_group" "app_logs" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/ec2/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
```

### 3. Dynamic Blocks

```hcl
resource "aws_security_group" "web" {
  name   = "${local.name_prefix}-web"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = local.common_tags
}
```

These best practices will help you write maintainable, secure, and scalable Terraform code.
