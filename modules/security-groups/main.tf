# Security Groups Module

locals {
  common_tags = merge(
    {
      Name        = var.name_prefix
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

#################
# Application Security Group
#################

resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # SSH access (be careful with this in production)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }
  }

  # Application port (configurable)
  dynamic "ingress" {
    for_each = var.app_port != null ? [1] : []
    content {
      description = "Application Port"
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # Outbound internet access
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-app-sg"
      Type = "application"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#################
# Database Security Group
#################

resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-database-"
  description = "Security group for database servers"
  vpc_id      = var.vpc_id

  # PostgreSQL access from app security group
  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # MySQL access from app security group
  ingress {
    description     = "MySQL from app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Custom database port
  dynamic "ingress" {
    for_each = var.database_port != null ? [1] : []
    content {
      description     = "Custom database port from app"
      from_port       = var.database_port
      to_port         = var.database_port
      protocol        = "tcp"
      security_groups = [aws_security_group.app.id]
    }
  }

  # Outbound access for updates/patches
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-database-sg"
      Type = "database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#################
# Load Balancer Security Group
#################

resource "aws_security_group" "alb" {
  count = var.create_alb_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Outbound to app servers
  egress {
    description     = "To application servers"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description     = "To application servers HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Custom app port
  dynamic "egress" {
    for_each = var.app_port != null ? [1] : []
    content {
      description     = "To application servers custom port"
      from_port       = var.app_port
      to_port         = var.app_port
      protocol        = "tcp"
      security_groups = [aws_security_group.app.id]
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-alb-sg"
      Type = "load-balancer"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#################
# EKS Security Group Rules (if needed)
#################

resource "aws_security_group" "eks_additional" {
  count = var.create_eks_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-eks-additional-"
  description = "Additional security group for EKS cluster"
  vpc_id      = var.vpc_id

  # Allow nodes to communicate with cluster API Server
  ingress {
    description = "Allow nodes to communicate with cluster API Server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  # Allow cluster to communicate with nodes
  egress {
    description = "Allow cluster to communicate with nodes"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name_prefix}-eks-additional-sg"
      Type = "eks"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
