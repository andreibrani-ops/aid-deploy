# Azure Virtual Desktop (AVD) Terraform Deployment

This Terraform configuration deploys a complete Azure Virtual Desktop environment with FSLogix profile management, scaling plans, and flexible domain join options.

## Architecture Overview

This deployment creates:
- **Host Pool**: Pooled desktop environment with auto-scaling
- **Session Hosts**: 2 Windows VMs joined to Azure AD or traditional AD
- **Networking**: Virtual network with subnet and security group
- **Storage**: Azure Files for FSLogix user profiles
- **User Management**: Azure AD group for AVD users
- **Scaling**: Automated scaling plan for weekdays and weekends

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (>= 1.0)
3. **Azure Subscription** - With appropriate permissions
4. **Azure AD Permissions** - To create groups and role assignments

## Quick Start

### 1. Authentication
```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"
```

### 2. Configuration
```bash
# Clone or download this repository
# Navigate to the project directory

# Copy the example variables file
cp terraform.tfvars.example dev.tfvars

# Edit dev.tfvars with your values
nano dev.tfvars
```

### 3. Deploy
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan -var-file="dev.tfvars"

# Deploy the infrastructure
terraform apply -var-file="dev.tfvars"
```

### 4. Access
After deployment, users can access AVD through:
- **Web Client**: https://rdweb.wvd.microsoft.com/arm/webclient
- **Windows Client**: Download from Microsoft Store
- **Mobile Apps**: Available for iOS and Android

## Configuration

### Required Variables
Edit your `.tfvars` file with these required values:

```hcl
environment = "dev"                    # Environment: dev, stage, or prod
customer_name = "contoso"              # Customer name for resource naming
admin_password = "YourSecurePassword!" # Local admin password for VMs
```

### Domain Join Options

#### Azure AD Join (Recommended)
```hcl
domain_join_type = "aad"  # Default - no additional config needed
```

#### Traditional Active Directory Join
```hcl
domain_join_type = "ad"
domain_name = "contoso.local"
domain_ou_path = "OU=AVD,DC=contoso,DC=local"
domain_admin_username = "contoso\\avdadmin"
domain_admin_password = "YourDomainAdminPassword!"
```

### Optional Configurations

```hcl
# Custom resource group name (auto-generated if not specified)
resource_group_name = "rg-custom-avd"

# Custom AVD users group name (auto-generated if not specified)  
avd_users_group_name = "Custom-AVD-Users"

# VM configuration
vm_size = "Standard_D4s_v3"           # Larger VM size
location = "East US"                   # Different Azure region

# Storage configuration
fslogix_share_size_gb = 500           # Larger profile storage
storage_account_tier = "Premium"      # Premium storage for better performance
```

## Post-Deployment Steps

### 1. Add Users to AVD
```bash
# Get the AVD users group name
terraform output avd_users_group_name

# Add users via Azure portal or Azure CLI
az ad group member add --group "AVD-Users-contoso-dev" --member-id "user-object-id"
```

### 2. Test Connection
1. Navigate to https://rdweb.wvd.microsoft.com/arm/webclient
2. Sign in with an assigned user account
3. Click on the desktop to launch a session

### 3. Monitor Resources
- Check scaling plan activity in Azure portal
- Monitor VM performance and user sessions
- Review FSLogix profile creation in storage account

## File Structure

```
├── main.tf                      # Main infrastructure resources
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output values
├── terraform.tfvars.example     # Example configuration
└── README.md                    # This file
```

## Key Features

### Auto Scaling
- **Weekdays**: Ramp up at 7 AM, peak hours 9 AM-6 PM, ramp down at 8 PM
- **Weekends**: Reduced capacity with 9 AM-8 PM schedule
- **Smart scaling**: Based on user sessions and capacity thresholds

### Security
- Network Security Groups with RDP access control
- Azure Files with network restrictions to AVD subnet only
- FSLogix profiles with proper RBAC permissions
- Encrypted storage with HTTPS-only access

### User Profiles
- FSLogix container-based profiles stored in Azure Files
- Dynamic VHDX files up to 30GB per user
- Automatic profile backup and high availability

## Troubleshooting

### Common Issues

**VMs not joining domain:**
- Check domain credentials and OU path
- Verify network connectivity to domain controllers
- Review VM extension logs in Azure portal

**Users can't access workspace:**
- Confirm user is added to AVD users group
- Check role assignments on application group
- Verify workspace is published correctly

**FSLogix profiles not working:**
- Check storage account network access rules
- Verify file share permissions
- Review FSLogix registry settings on VMs

### Useful Commands

```bash
# Check deployment status
terraform show

# View outputs
terraform output

# Destroy infrastructure (careful!)
terraform destroy -var-file="dev.tfvars"

# Refresh state
terraform refresh -var-file="dev.tfvars"
```

## Cost Optimization

- Use **B-series burstable VMs** for development environments
- Configure **scaling plans** to shut down VMs during off-hours  
- Use **Standard storage** for non-production FSLogix profiles
- Set appropriate **maximum sessions per host** (currently 10)

## Security Best Practices

1. **Use Azure Key Vault** for sensitive passwords (future enhancement)
2. **Enable MFA** for all AVD users
3. **Configure Conditional Access** policies
4. **Regular security updates** via Azure Update Management
5. **Monitor with Azure Security Center**

## Support

For issues with this Terraform configuration:
1. Check the troubleshooting section above
2. Review Terraform and Azure provider documentation
3. Validate your Azure permissions and quotas

For AVD-specific issues, consult the [official Azure Virtual Desktop documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/).