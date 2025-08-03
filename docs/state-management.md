# Terraform State Management Guide

## What is Terraform State?

Terraform state is a file that keeps track of the resources Terraform manages. It's essentially a mapping between your Terraform configuration and the real-world resources.

### Key Points about State:
- **State File**: Contains resource metadata and current state
- **State Locking**: Prevents concurrent operations
- **Remote State**: Shared state storage for team collaboration
- **State Versioning**: Track changes over time

## Why Remote State?

### Problems with Local State:
1. **Not shareable** - Team members can't collaborate
2. **No locking** - Risk of corruption from concurrent operations
3. **No backup** - Risk of losing infrastructure state
4. **Security** - Sensitive data stored locally

### Benefits of Remote State:
1. **Team Collaboration** - Shared state accessible by all team members
2. **State Locking** - Prevents conflicts during operations
3. **Encryption** - State data encrypted at rest and in transit
4. **Versioning** - Track state changes over time
5. **Backup** - Automatic backups and disaster recovery

## AWS Remote State Setup

### Required AWS Resources:

#### 1. S3 Bucket for State Storage
```hcl
# This should be created manually or via a separate Terraform configuration
resource "aws_s3_bucket" "terraform_state" {
  bucket = "your-company-terraform-state-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

#### 2. DynamoDB Table for State Locking
```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-state-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Locks"
  }
}
```

## Backend Configuration

### Example backend.tf for each environment:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-company-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

### Key Considerations:
- **Unique Keys**: Each environment should have a unique state key
- **Encryption**: Always enable encryption
- **Region**: Use the same region for consistency
- **Naming**: Use descriptive bucket and table names

## State Management Best Practices

### 1. Environment Separation
```
State Keys:
- environments/dev/terraform.tfstate
- environments/staging/terraform.tfstate  
- environments/prod/terraform.tfstate
- shared/iam/terraform.tfstate
```

### 2. State File Organization
- **Separate states for separate concerns**
- **Environment-specific state files**
- **Shared resources in separate state**

### 3. State Operations

#### Initialize Backend:
```bash
terraform init
```

#### State Commands:
```bash
# List resources in state
terraform state list

# Show resource details
terraform state show aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.example

# Move resource in state
terraform state mv aws_instance.example aws_instance.new_name
```

### 4. State File Security
- **Never commit state files to version control**
- **Use IAM roles for backend access**
- **Enable S3 bucket encryption**
- **Restrict S3 bucket access**
- **Enable CloudTrail for audit logging**

### 5. State Backup Strategy
- **S3 versioning enabled**
- **Cross-region replication** (for critical environments)
- **Regular state file exports**
- **Disaster recovery procedures**

## Common State Issues and Solutions

### 1. State Drift
**Problem**: Real resources don't match state file
**Solution**: 
```bash
terraform plan  # Review differences
terraform apply # Apply changes to fix drift
```

### 2. State Lock Issues
**Problem**: State locked by previous operation
**Solution**:
```bash
terraform force-unlock LOCK_ID
```

### 3. State Corruption
**Problem**: State file corrupted
**Solution**:
- Restore from S3 versioning
- Use terraform import to rebuild state

### 4. Resource Import
**Problem**: Resources created outside Terraform
**Solution**:
```bash
terraform import aws_instance.example i-1234567890abcdef0
```

## Multi-Environment Strategy

### Workspace vs. Separate Directories

#### Separate Directories (Recommended):
```
environments/
├── dev/
├── staging/
└── prod/
```

**Pros**:
- Clear separation
- Different backend configurations
- Environment-specific variables
- Reduced risk of mistakes

#### Terraform Workspaces:
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

**Pros**:
- Single codebase
- Easy switching between environments

**Cons**:
- Shared backend configuration
- Higher risk of cross-environment mistakes

## Monitoring and Alerting

### CloudWatch Alarms for State Operations
- Monitor S3 bucket access
- Track DynamoDB lock table usage
- Alert on state file changes

### AWS Config Rules
- Monitor compliance of state bucket configuration
- Ensure encryption is enabled
- Verify public access is blocked

## Migration Strategies

### From Local to Remote State:
1. Create S3 bucket and DynamoDB table
2. Add backend configuration
3. Run `terraform init` to migrate state

### Between Backends:
1. Update backend configuration
2. Run `terraform init -migrate-state`
3. Verify state integrity

This comprehensive guide covers the essential aspects of Terraform state management. Understanding these concepts is crucial before writing any infrastructure code.
