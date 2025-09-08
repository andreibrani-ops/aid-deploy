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

resource "azurerm_virtual_desktop_scaling_plan" "pooled" {
  name                = "sp-${local.resource_prefix}-pooled"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  friendly_name       = "Scaling plan for ${local.resource_prefix} pooled desktop"
  description         = "Scaling plan for pooled desktop environment"
  time_zone           = var.time_zone

  schedule {
    name                                 = "weekdays_schedule"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "07:00"
    ramp_up_load_balancing_algorithm     = "DepthFirst"
    ramp_up_minimum_hosts_percent        = 50
    ramp_up_capacity_threshold_percent   = 60

    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "DepthFirst"

    ramp_down_start_time                 = "18:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 25
    ramp_down_capacity_threshold_percent = 50
    ramp_down_force_logoff_users         = false
    ramp_down_stop_hosts_when            = "ZeroActiveSessions"
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "You will be logged off in 45 min. Make sure to save your work."

    off_peak_start_time                  = "20:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  schedule {
    name                                 = "weekends_schedule"
    days_of_week                         = ["Saturday", "Sunday"]
    ramp_up_start_time                   = "09:00"
    ramp_up_load_balancing_algorithm     = "DepthFirst"
    ramp_up_minimum_hosts_percent        = 25
    ramp_up_capacity_threshold_percent   = 60

    peak_start_time                      = "10:00"
    peak_load_balancing_algorithm        = "DepthFirst"

    ramp_down_start_time                 = "18:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_capacity_threshold_percent = 50
    ramp_down_force_logoff_users         = false
    ramp_down_stop_hosts_when            = "ZeroActiveSessions"
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "You will be logged off in 45 min. Make sure to save your work."

    off_peak_start_time                  = "20:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.pooled.id
    scaling_plan_enabled = true
  }

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = "dag-${local.resource_prefix}-desktop"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.pooled.id
  friendly_name = "Desktop Application Group"
  description   = "Desktop Application Group for ${local.resource_prefix}"

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "ws-${local.resource_prefix}-avd"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name

  friendly_name = "${local.resource_prefix} AVD Workspace"
  description   = "AVD Workspace for ${local.resource_prefix}"

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
  }
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_app_group" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

resource "azuread_group" "avd_users" {
  display_name     = local.avd_users_group_name
  description      = "AVD Users group for ${local.resource_prefix} environment"
  security_enabled = true
}

resource "azurerm_role_assignment" "desktop_virtualization_user" {
  scope                = azurerm_virtual_desktop_application_group.desktop.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_group.avd_users.object_id
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "fslogix" {
  name                = "st${replace(local.resource_prefix, "-", "")}${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location

  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"

  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.avd.id]
    bypass                     = ["AzureServices"]
  }

  tags = {
    Environment = var.environment
    Customer    = var.customer_name
    Purpose     = "FSLogix"
  }
}

resource "azurerm_storage_share" "fslogix_profiles" {
  name                 = "fslogix-profiles"
  storage_account_name = azurerm_storage_account.fslogix.name
  quota                = var.fslogix_share_size_gb

  metadata = {
    environment = var.environment
    customer    = var.customer_name
  }
}

resource "azurerm_role_assignment" "fslogix_storage_contributor" {
  scope                = azurerm_storage_account.fslogix.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azuread_group.avd_users.object_id
}