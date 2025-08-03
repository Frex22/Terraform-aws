# Terraform State Backend Setup Guide

This guide will help you set up the required AWS resources for remote state management before using this Terraform configuration.

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform installed (version >= 1.0)
3. Access to create S3 buckets and DynamoDB tables

## Step 1: Create State Backend Resources

### Option A: Manual Creation (Recommended for learning)

#### 1. Create S3 Bucket for State Storage

```bash
# Set your variables
export BUCKET_NAME="your-company-terraform-state-$(openssl rand -hex 4)"
export REGION="us-west-2"

# Create the bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### 2. Create DynamoDB Table for State Locking

```bash
# Create DynamoDB table
aws dynamodb create-table \
    --table-name terraform-state-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
```

### Option B: Using Terraform Bootstrap

Create a separate Terraform configuration to bootstrap your backend:

#### bootstrap/main.tf
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.bucket_prefix}-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "your-company-terraform-state"
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
```

Run the bootstrap:
```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

## Step 2: Configure Your Project

1. **Update backend configuration** in each environment's `backend.tf` file:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-actual-bucket-name"
       key            = "environments/dev/terraform.tfstate"
       region         = "us-west-2"
       dynamodb_table = "terraform-state-locks"
       encrypt        = true
     }
   }
   ```

2. **Create terraform.tfvars** from the example file:
   ```bash
   cd environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

## Step 3: Initialize and Deploy

1. **Initialize Terraform**:
   ```bash
   cd environments/dev
   terraform init
   ```

2. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

## Best Practices

### Security
- Never commit `.tfvars` files with sensitive data
- Use IAM roles and least privilege access
- Enable CloudTrail for audit logging
- Regularly rotate access keys

### State Management
- Use separate state files per environment
- Enable S3 versioning for state backup
- Monitor state file access with CloudWatch
- Implement automated backups

### Team Collaboration
- Use consistent naming conventions
- Document all modules and variables
- Implement CI/CD pipelines for Terraform
- Use pull request reviews for changes

## Common Commands

```bash
# Initialize backend
terraform init

# Switch between environments
cd environments/dev
cd environments/staging
cd environments/prod

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state
terraform refresh

# Destroy infrastructure (be careful!)
terraform destroy
```

## Troubleshooting

### Backend Issues
- Ensure S3 bucket exists and you have access
- Verify DynamoDB table exists
- Check AWS credentials and permissions

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### State Corruption
- Restore from S3 versioning
- Use `terraform import` to rebuild state
- Implement regular state backups

## Next Steps

1. Read through the documentation in the `docs/` folder
2. Understand the module structure
3. Start with the development environment
4. Gradually add complexity as you learn

Remember: Always test in development before applying to production!
