# Backend Configuration for Development Environment
# 
# IMPORTANT: Create the S3 bucket and DynamoDB table BEFORE using this backend
# See docs/state-management.md for setup instructions

terraform {
  backend "s3" {
    # Replace with your actual bucket name
    bucket = "your-company-terraform-state"
    
    # Unique state file for dev environment
    key = "environments/dev/terraform.tfstate"
    
    # AWS region where your state bucket is located
    region = "us-west-2"
    
    # DynamoDB table for state locking
    dynamodb_table = "terraform-state-locks"
    
    # Enable state file encryption
    encrypt = true
    
    # Additional security settings
    # versioning = true  # Enable S3 bucket versioning
    # server_side_encryption_configuration {
    #   rule {
    #     apply_server_side_encryption_by_default {
    #       sse_algorithm = "AES256"
    #     }
    #   }
    # }
  }
}

# Optional: Additional backend configuration for workspace isolation
# You can also use Terraform workspaces as an alternative approach
# 
# To use workspaces instead of separate backend files:
# terraform workspace new dev
# terraform workspace select dev
