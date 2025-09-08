output "resource_group_name" {
  description = "Name of the resource group containing AVD resources"
  value       = azurerm_resource_group.avd.name
}

output "workspace_name" {
  description = "Name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.name
}

output "workspace_friendly_name" {
  description = "Friendly name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.friendly_name
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.pooled.name
}

output "host_pool_id" {
  description = "ID of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.pooled.id
}

output "application_group_name" {
  description = "Name of the desktop application group"
  value       = azurerm_virtual_desktop_application_group.desktop.name
}

output "avd_users_group_name" {
  description = "Name of the Azure AD group for AVD users"
  value       = azuread_group.avd_users.display_name
}

output "avd_users_group_id" {
  description = "Object ID of the Azure AD group for AVD users"
  value       = azuread_group.avd_users.object_id
}

output "storage_account_name" {
  description = "Name of the FSLogix storage account"
  value       = azurerm_storage_account.fslogix.name
}

output "storage_account_id" {
  description = "ID of the FSLogix storage account"
  value       = azurerm_storage_account.fslogix.id
}

output "file_share_name" {
  description = "Name of the FSLogix profiles file share"
  value       = azurerm_storage_share.fslogix_profiles.name
}

output "file_share_url" {
  description = "URL of the FSLogix profiles file share"
  value       = "\\\\${azurerm_storage_account.fslogix.name}.file.core.windows.net\\${azurerm_storage_share.fslogix_profiles.name}"
}

output "session_host_names" {
  description = "Names of the session host VMs"
  value       = azurerm_windows_virtual_machine.session_host[*].name
}

output "session_host_private_ips" {
  description = "Private IP addresses of the session host VMs"
  value       = azurerm_network_interface.session_host[*].private_ip_address
}

output "virtual_network_name" {
  description = "Name of the AVD virtual network"
  value       = azurerm_virtual_network.avd.name
}

output "subnet_name" {
  description = "Name of the AVD subnet"
  value       = azurerm_subnet.avd.name
}

output "scaling_plan_name" {
  description = "Name of the scaling plan"
  value       = azurerm_virtual_desktop_scaling_plan.pooled.name
}

output "domain_join_type" {
  description = "Type of domain join configured (aad or ad)"
  value       = var.domain_join_type
}