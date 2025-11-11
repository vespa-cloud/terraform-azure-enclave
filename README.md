# Vespa Cloud Enclave on Azure

This Terraform module bootstraps a Microsoft Azure subscription with the identities, roles and
subscription features required to run Vespa Cloud Enclaves on Azure. It also exposes the set of
supported Vespa Cloud zones so you can create one or more Enclave networks using the provided
zone submodule.

See Vespa Cloud documentation: https://cloud.vespa.ai/

## 📦 Module registries

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-vespa--cloud%2Fenclave%2Fazure-623CE4?logo=terraform&logoColor=white)](https://registry.terraform.io/modules/vespa-cloud/enclave/azure)
[![OpenTofu Registry](https://img.shields.io/badge/OpenTofu%20Registry-vespa--cloud%2Fenclave%2Fazure-FFDA18?logo=opentofu&logoColor=white)](https://search.opentofu.org/module/vespa-cloud/enclave/azure)

This module is published on both the Terraform and OpenTofu registries.

- Module address (both): `vespa-cloud/enclave/azure`
- Terraform Registry: https://registry.terraform.io/modules/vespa-cloud/enclave/azure
- OpenTofu Registry: https://search.opentofu.org/module/vespa-cloud/enclave/azure


## What this module sets up
- A `system` resource group to host identities used by Vespa Cloud
- User-assigned managed identities for the tenant, the Vespa provisioner, and Athenz
- Custom roles and role assignments that allow Vespa Cloud to provision and manage VMs, NICs,
  public IPs and load balancers in your subscription
- Federated identity credentials (OIDC) for Athenz and the Vespa provisioner
- Registration of the `EncryptionAtHost` feature in the subscription

Networking (VNet, subnets, bastion, storage for archives/disks, etc.) is created per-zone via
the `modules/zone` submodule after the root module has been applied.

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
  source      = "vespa-cloud/enclave/azure"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
}

# Create one Vespa Cloud zone (VNet, subnets, bastion, storage, etc.)
module "zone_dev_azure_eastus_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.dev.azure_eastus_az1

  # Allow Vespa Cloud operators to SSH into the provisioned VMs for troubleshooting.
  #enable_ssh = true
}

output "enclave_config" {
  value = module.enclave.enclave_config
}
```
### Optional: enable SSH access in a zone
Set `enable_ssh = true` (the commented line above) in a zone module block to provision Azure Bastion in that
zone VNet, giving Vespa Cloud operators secure SSH access for troubleshooting. Default is `false` (no Bastion).

See complete working example in `examples/basic`.

## Inputs
- tenant_name (string, required): The Vespa Cloud tenant name that will operate in this subscription.

### Internal-use inputs (do not override)
- __zts_url (string, optional, default "https://zts.athenz.vespa-cloud.com:4443/zts/v1"): INTERNAL. Athenz ZTS issuer URL for federated identity credentials. Do not override.
- __all_zones (list(object), optional): INTERNAL. Default list of Azure Vespa Cloud zones. Do not override.

Internal inputs (prefixed with double underscores) are not part of the public,
stable API and may change without notice.

## Outputs
- enclave_config (map): Map of various properties that must be shared with Vespa team to finalize enclave setup. Propagate this result
  up to the root module for easy access to its values. Print the output with
  ```
  terraform output enclave_config
  ```
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
- azurerm_role_definition: `provisioner`, `athenz`, `archive-writer-no-delete-${subscription_id}`
- azurerm_role_assignment for the above roles at subscription and resource group scopes
- azurerm_federated_identity_credential for Athenz and provisioner
- azapi_resource_action to register `Microsoft.Compute/features/EncryptionAtHost`

Note: Custom role names in Azure are unique per Microsoft Entra directory (tenant), hence the subscription-id suffix.

## Permissions needed by the Terraform runner
The principal running Terraform must be able to create custom role definitions and assignments at the
subscription scope, managed identities, resource groups, and register features. For provisioning
resources in zone submodules, ensure the principal has data-plane RBAC such as `Storage Account Contributor`
on the created storage accounts.

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
