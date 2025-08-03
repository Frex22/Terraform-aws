# Makefile for Terraform Operations
# This Makefile provides convenient commands for common Terraform operations

.PHONY: help init plan apply destroy fmt validate clean bootstrap

# Default environment
ENV ?= dev

# Colors for output
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
RESET  := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Terraform Project Commands$(RESET)"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo
	@echo "$(YELLOW)Usage Examples:$(RESET)"
	@echo "  make init ENV=dev     # Initialize dev environment"
	@echo "  make plan ENV=staging # Plan staging environment"
	@echo "  make apply ENV=prod   # Apply prod environment"

init: ## Initialize Terraform for specified environment
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform init

plan: ## Create Terraform plan for specified environment
	@echo "$(BLUE)Creating plan for $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform plan

apply: ## Apply Terraform changes for specified environment
	@echo "$(YELLOW)Applying changes to $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform apply

destroy: ## Destroy Terraform-managed infrastructure (use with caution)
	@echo "$(RED)WARNING: This will destroy infrastructure in $(ENV) environment!$(RESET)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd environments/$(ENV) && terraform destroy; \
	else \
		echo "Cancelled."; \
	fi

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(RESET)"
	terraform fmt -recursive .

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(RESET)"
	@for env in dev staging prod; do \
		echo "Validating $$env environment..."; \
		cd environments/$$env && terraform validate && cd ../..; \
	done

clean: ## Clean Terraform temporary files
	@echo "$(BLUE)Cleaning Terraform temporary files...$(RESET)"
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete
	find . -name ".terraform.lock.hcl" -delete

bootstrap: ## Bootstrap backend resources (S3 bucket and DynamoDB table)
	@echo "$(BLUE)Bootstrapping Terraform backend resources...$(RESET)"
	@if [ ! -d "bootstrap" ]; then \
		echo "$(RED)Bootstrap directory not found. Please create it first.$(RESET)"; \
		exit 1; \
	fi
	cd bootstrap && terraform init && terraform apply

# Environment-specific shortcuts
init-dev: ## Initialize dev environment
	@$(MAKE) init ENV=dev

plan-dev: ## Plan dev environment
	@$(MAKE) plan ENV=dev

apply-dev: ## Apply dev environment
	@$(MAKE) apply ENV=dev

init-staging: ## Initialize staging environment
	@$(MAKE) init ENV=staging

plan-staging: ## Plan staging environment
	@$(MAKE) plan ENV=staging

apply-staging: ## Apply staging environment
	@$(MAKE) apply ENV=staging

init-prod: ## Initialize prod environment
	@$(MAKE) init ENV=prod

plan-prod: ## Plan prod environment
	@$(MAKE) plan ENV=prod

apply-prod: ## Apply prod environment
	@$(MAKE) apply ENV=prod

# State management commands
state-list: ## List resources in Terraform state
	@echo "$(BLUE)Listing resources in $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform state list

state-show: ## Show specific resource (usage: make state-show ENV=dev RESOURCE=aws_vpc.main)
	@echo "$(BLUE)Showing resource $(RESOURCE) in $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform state show $(RESOURCE)

output: ## Show Terraform outputs
	@echo "$(BLUE)Showing outputs for $(ENV) environment...$(RESET)"
	cd environments/$(ENV) && terraform output

# Documentation
docs: ## Generate module documentation
	@echo "$(BLUE)Generating module documentation...$(RESET)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		for module in modules/*/; do \
			echo "Generating docs for $$module"; \
			terraform-docs markdown table $$module > $$module/README.md; \
		done; \
	else \
		echo "$(YELLOW)terraform-docs not found. Install it with: go install github.com/terraform-docs/terraform-docs@latest$(RESET)"; \
	fi

# Security checks
security: ## Run security checks on Terraform code
	@echo "$(BLUE)Running security checks...$(RESET)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "$(YELLOW)tfsec not found. Install it with: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest$(RESET)"; \
	fi

# Linting
lint: ## Lint Terraform code
	@echo "$(BLUE)Linting Terraform code...$(RESET)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --recursive; \
	else \
		echo "$(YELLOW)tflint not found. Install it from: https://github.com/terraform-linters/tflint$(RESET)"; \
	fi

# All checks
check: fmt validate lint security ## Run all checks (format, validate, lint, security)

# Setup development environment
setup: ## Setup development environment with tools
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@echo "Installing recommended tools..."
	@echo "1. Install terraform-docs: go install github.com/terraform-docs/terraform-docs@latest"
	@echo "2. Install tfsec: go install github.com/aquasecurity/tfsec/cmd/tfsec@latest"
	@echo "3. Install tflint: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
	@echo "4. Install pre-commit: pip install pre-commit"
	@echo "$(GREEN)Run these commands manually to install the tools.$(RESET)"
