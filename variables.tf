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

variable "fslogix_share_size_gb" {
  description = "Size of the FSLogix file share in GB"
  type        = number
  default     = 100
}

variable "storage_account_tier" {
  description = "Performance tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "domain_join_type" {
  description = "Type of domain join: 'aad' for Azure AD join or 'ad' for traditional AD domain join"
  type        = string
  default     = "aad"
  validation {
    condition     = contains(["aad", "ad"], var.domain_join_type)
    error_message = "Domain join type must be either 'aad' or 'ad'."
  }
}

variable "domain_name" {
  description = "Domain name for traditional AD join (only used when domain_join_type is 'ad')"
  type        = string
  default     = ""
}

variable "domain_ou_path" {
  description = "OU path for domain join (only used when domain_join_type is 'ad')"
  type        = string
  default     = ""
}

variable "domain_admin_username" {
  description = "Domain administrator username for AD join (only used when domain_join_type is 'ad')"
  type        = string
  default     = ""
}

variable "domain_admin_password" {
  description = "Domain administrator password for AD join (only used when domain_join_type is 'ad')"
  type        = string
  default     = ""
  sensitive   = true
}

locals {
  resource_prefix = "${var.customer_name}-${var.environment}"
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "rg-${local.resource_prefix}-avd"
  avd_users_group_name = var.avd_users_group_name != "" ? var.avd_users_group_name : "AVD-Users-${local.resource_prefix}"
}