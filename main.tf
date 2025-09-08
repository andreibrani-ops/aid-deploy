terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

resource "azurerm_resource_group" "avd" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_virtual_desktop_host_pool" "pooled" {
  name                = "hp-${local.resource_prefix}-pooled"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  type               = "Pooled"
  load_balancer_type = "DepthFirst"
  
  maximum_sessions_allowed = 10
  start_vm_on_connect      = true
  
  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}