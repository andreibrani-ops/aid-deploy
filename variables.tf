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
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = ""
}

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "avdadmin"
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true
}

variable "time_zone" {
  description = "Time zone for scaling schedules"
  type        = string
  default     = "W. Europe Standard Time"
}

variable "avd_users_group_name" {
  description = "Name of the Azure AD group for AVD users"
  type        = string
  default     = ""
}

locals {
  resource_prefix = "${var.customer_name}-${var.environment}"
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-${local.resource_prefix}-avd"
  avd_users_group_name = var.avd_users_group_name != "" ? var.avd_users_group_name : "AVD-Users-${local.resource_prefix}"
}