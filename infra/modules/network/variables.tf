variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be between 2 and 3."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets (cheaper for dev)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "app_port" {
  description = "Application port exposed by ECS tasks"
  type        = number
  default     = 80
}
