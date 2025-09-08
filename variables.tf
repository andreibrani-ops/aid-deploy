variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "customer_name" {
  description = "Customer name for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

locals {
  resource_prefix = "${var.customer_name}-${var.environment}"
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-${local.resource_prefix}-avd"
}