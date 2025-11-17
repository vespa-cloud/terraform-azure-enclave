# Multi-Region Vespa Cloud Enclave Example

This example demonstrates how to provision multiple Vespa Cloud zones across different environments and regions.

## What This Example Shows

- **Multiple zones** across test, staging, and production environments
- **Multi-region setup** with zones in both US and EU

## Architecture

This example provisions:
- `test.azure-eastus-az1` - Test environment in US East
- `staging.azure-eastus-az1` - Staging environment in US East
- `prod.azure-eastus-az1` - Production environment in US East
- `prod.azure-westeurope-az1` - Production environment in EU West

Each zone gets:
- VNet with dual-stack IPv4/IPv6 addressing
- NAT Gateway for outbound connectivity
- Storage accounts for archives and disk images
- Key Vault with HSM-backed encryption
- Disk encryption set with auto-rotation
- Azure Bastion for SSH access (when enabled)

## Usage

1. **Update configuration**:
   ```hcl
   subscription_id = "your-azure-subscription-id"
   tenant_name     = "your-vespa-tenant-name"
   ```

2. **Customize zones** by editing the module blocks:
   ```hcl
   module "zone_prod_azure_eastus_az1" {
     source  = "vespa-cloud/enclave/azure//modules/zone"
     version = ">= 1.0.0, < 2.0.0"
     zone    = module.enclave.zones.prod.azure_eastus_az1

     enable_ssh                  = false
     archive_reader_principals   = []
   }
   ```

3. **Add or remove zones** by adding/removing module blocks

4. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Share the output** with Vespa team:
   ```bash
   terraform output enclave_config
   ```

## Important Notes

### Zone Availability

Check the module's `zones` output for available zones.

### Zone Module Settings

Common zone module settings:
- `enable_ssh` - Enable/disable SSH access via Azure Bastion
- `archive_reader_principals` - List of principal IDs that need read access to archives

## Next Steps

After applying the configuration:
1. Share the `enclave_config` output with the Vespa team
2. Wait for Vespa team to complete enclave setup
3. Deploy your Vespa application to the provisioned zones

## See Also

- [Basic Example](../basic/) - Single-zone setup
- [Module README](../../README.md) - Complete module documentation
- [Vespa Cloud Documentation](https://cloud.vespa.ai/)
