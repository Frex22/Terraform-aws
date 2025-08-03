# Terraform Learning Guide

## Overview
This repository demonstrates Terraform best practices for AWS infrastructure, focusing on modular design, proper state management, and organizational structure.

## Directory Structure

```
terraform/
├── README.md                    # This file
├── .gitignore                  # Git ignore file for Terraform
├── terraform.tf               # Terraform and provider configuration
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/                   # Reusable modules
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── security-groups/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── shared/                    # Shared resources (IAM roles, etc.)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
└── docs/                     # Documentation
    ├── state-management.md
    ├── best-practices.md
    └── module-guidelines.md
```

## Key Concepts

### 1. Environment Separation
- **dev/**: Development environment for testing
- **staging/**: Pre-production environment
- **prod/**: Production environment
- Each environment has its own state file and configuration

### 2. Module Structure
- **modules/**: Reusable infrastructure components
- Each module is self-contained with its own variables, outputs, and documentation
- Modules should be environment-agnostic

### 3. State Management
- Remote state backend (S3 + DynamoDB for locking)
- Separate state files per environment
- State file encryption and versioning

## Getting Started

1. Read the documentation in the `docs/` folder
2. Start with the development environment
3. Understand state management before proceeding
4. Create modules before environments

## Prerequisites

- AWS CLI configured
- Terraform installed (version >= 1.0)
- S3 bucket for state storage
- DynamoDB table for state locking
