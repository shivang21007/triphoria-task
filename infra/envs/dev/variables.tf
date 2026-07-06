variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "triphoria"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Explicit AZs for plan-only runs without live AWS discovery"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway (cost saving for dev)"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "RDS backup retention in days"
  type        = number
  default     = 3
}

variable "db_deletion_protection" {
  description = "RDS deletion protection"
  type        = bool
  default     = false
}

variable "db_multi_az" {
  description = "RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "ecs_cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired ECS task count"
  type        = number
  default     = 1
}

variable "container_image" {
  description = "Placeholder application image"
  type        = string
  default     = "nginx:1.27-alpine"
}
