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

resource "azurerm_virtual_network" "avd" {
  name                = "vnet-${local.resource_prefix}-avd"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_subnet" "avd" {
  name                 = "subnet-${local.resource_prefix}-avd"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "avd" {
  name                = "nsg-${local.resource_prefix}-avd"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_subnet_network_security_group_association" "avd" {
  subnet_id                 = azurerm_subnet.avd.id
  network_security_group_id = azurerm_network_security_group.avd.id
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "pooled" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.pooled.id
  expiration_date = timeadd(timestamp(), "48h")
}

resource "azurerm_network_interface" "session_host" {
  count               = 2
  name                = "nic-${local.resource_prefix}-sh-${count.index + 1}"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_windows_virtual_machine" "session_host" {
  count               = 2
  name                = "vm-${local.resource_prefix}-sh-${count.index + 1}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.session_host[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-avd"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_virtual_machine_extension" "avd_agent" {
  count                = 2
  name                 = "avd-agent-${count.index + 1}"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"

  settings = jsonencode({
    modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip"
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      hostPoolName          = azurerm_virtual_desktop_host_pool.pooled.name
      registrationInfoToken = azurerm_virtual_desktop_host_pool_registration_info.pooled.token
    }
  })

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}