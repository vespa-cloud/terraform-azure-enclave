# Vespa Cloud Enclave on Azure

This Terraform module bootstraps a Microsoft Azure subscription with the identities, roles and
subscription features required to run Vespa Cloud Enclaves on Azure. It also exposes the set of
supported Vespa Cloud zones so you can create one or more Enclave networks using the provided
zone submodule.

- Module on the Terraform Registry: https://registry.terraform.io/modules/vespa-cloud/enclave/azure
- Vespa Cloud documentation: https://cloud.vespa.ai/

## What this module sets up
- A `system` resource group to host identities used by Vespa Cloud
- User-assigned managed identities for the tenant, the Vespa provisioner, and Athenz
- Custom roles and role assignments that allow Vespa Cloud to provision and manage VMs, NICs,
  public IPs and load balancers in your subscription
- Federated identity credentials (OIDC) for Athenz and the Vespa provisioner
- Registration of the `EncryptionAtHost` feature in the subscription

Networking (VNet, subnets, bastion, storage for archives/disks, etc.) is created per-zone via
the `modules/zone` submodule once the root module has been applied.

## Requirements
- Terraform >= 1.3
- AzureRM provider (hashicorp/azurerm)
- AzAPI provider (azure/azapi)
- Azure subscription where you have sufficient permissions to:
  - Create resource groups
  - Create user-assigned managed identities and federated credentials
  - Create custom role definitions and role assignments at the subscription scope
  - Register subscription features (e.g. `EncryptionAtHost`)

Authentication: configure the AzureRM provider using any supported auth method (CLI, Managed Identity,
Workload Identity, Service Principal). See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

## Usage
Minimal example (you must add at least one zone submodule):

```hcl
# Providers
provider "azurerm" {
  features {}
  subscription_id = "<YOUR-SUBSCRIPTION-ID>"

  # Optional but recommended for Storage interactions in submodules
  storage_use_azuread = true
}
provider "azapi" {}

# Bootstrap your subscription for Vespa Cloud
module "enclave" {
  source      = "github.com/vespa-cloud/terraform-azure-enclave"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-TENANT-NAME>"
}

# Create one Vespa Cloud zone (VNet, subnets, bastion, storage, etc.)
module "zone_dev_azure_eastus_az1" {
  source  = "github.com/vespa-cloud/terraform-azure-enclave//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.dev.azure_eastus_az1
}
```

See complete working example in `examples/basic`.

## Inputs
- tenant_name (string, required): The Vespa Cloud tenant name that will operate in this subscription.
- athenz_env (string, optional, default "prod"): Only for internal use. Athenz environment selector for ZTS issuer URL.
- all_zones (list(object), optional): Only for internal use. Default list of Azure Vespa Cloud zones.

## Outputs
- zones (map): Map of available Vespa Cloud zones grouped by environment. Keys are referenced as
  `[environment].[region with - replaced by _]`, for example: `prod.azure_eastus_az1` or `dev.azure_eastus_az1`.
  Each zone object contains:
  - name: Full Vespa Cloud zone name (e.g. `prod.azure-eastus-az1`)
  - short_name: Short name used in hostnames (e.g. `prod.eastus-az1`)
  - region: Vespa region id with dashes (e.g. `azure-eastus-az1`)
  - azure_region: Azure region extracted from the physical zone (e.g. `eastus`)

## Providers
- hashicorp/azurerm
- azure/azapi

## Resources created (high level)
- azurerm_resource_group.system (name: `system`)
- azurerm_user_assigned_identity: `id-tenant`, `id-provisioner`, `id-athenz`
- azurerm_role_definition: `provisioner`, `athenz`
- azurerm_role_assignment for the above roles at subscription and resource group scopes
- azurerm_federated_identity_credential for Athenz and provisioner
- azapi_resource_action to register `Microsoft.Compute/features/EncryptionAtHost`

## Permissions needed by the Terraform runner
The principal running Terraform must be able to create custom role definitions and assignments at the
subscription scope, managed identities, resource groups, and register features. For provisioning
resources in zone submodules the principal must have Storage Account Contributor on the created 
storage accounts.

Option A (simplest for bootstrap):
- `Owner` @ subscription

Option B (least‑privilege):
- `Contributor` @ subscription
- `User Access Administrator` @ subscription
- Plus either:
  - A one‑time admin action to pre‑create the two custom role definitions used by the module.
    If your organization restricts feature registration, also have an admin register the `EncryptionAtHost`
    feature once; otherwise `Contributor` typically suffices for registration.
  - Or grant a custom role that includes `Microsoft.Authorization/roleDefinitions/*` at the subscription scope so the runner can create role definitions itself.
- `Storage Account Contributor` on target storage accounts or parent scope.

## Versioning
This module follows semantic versioning. Pin a compatible version range when consuming the module, for example:
`>= 1.0.0, < 2.0.0`.

## Examples
- Basic: ./examples/basic

## License
Apache-2.0. See LICENSE.
