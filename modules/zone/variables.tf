variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    name          = string, // The Vespa Cloud zone name, e.g. prod.azure-eastus-az1
    short_name    = string, // The Vespa Cloud short name used in e.g. hostnames, e.g. prod.eastus-az1
    environment   = string, // The Vespa Cloud environment, e.g. prod
    region        = string, // The Vespa Cloud region, e.g. azure-eastus-az1
    azure_region  = string, // The Azure region, e.g. eastus
    physical_zone = string, // The physical (availability) zone, e.g. eastus-az1

    # Internal infrastructure details - automatically populated from enclave module
    enclave_infra = object({
      tenant_name                     = string
      archive_writer_role_resource_id = string
      id_tenant_principal_id          = string
      id_operator_principal_id        = string
      operator_role_definition_id     = string
    })
  })
}

variable "archive_reader_principals" {
  description = "List of principal ids granted read access to the archive blob storage"
  type        = list(string)
  default     = []
}

variable "enable_ssh" {
  description = "Allow Vespa Cloud operators to SSH to VMs"
  type        = bool
  default     = false
}

variable "key_officers" {
  description = "Azure principal IDs of key vault officers (in addition to the current user), e.g. for disk encryption"
  type        = list(string)
  default     = []
}

// An IPv4 CIDR that determines the address space to be used for the Vespa Enclave zone.
//
// Example for CIDR 10.128.0.0/16.  The first 16 bits defines the network prefix,
// and the remaining bits will be used as follows:
//     Bits:                 31  30 ...  16  15  14  13  12 ... 1  0
//     Tenant host subnet:  [network prefix]  1 [         host part ]
//     Bastion subnet:      [network prefix]  0   0   0 [ host part ]
variable "network_ipv4_cidr" {
  description = "IPv4 CIDR for zone network"
  type        = string
  default     = "10.128.0.0/16"
  validation {
    condition = (
      startswith(cidrsubnet(var.network_ipv4_cidr, 0, 0), "10.") &&
      try(tonumber(element(split("/", var.network_ipv4_cidr), 1)) == 16, false)
    )

    error_message = "CIDR for the IPv4 zone network must be 10.x.0.0/16"
  }
}

// An IPv6 CIDR that determines the address space to be used for the Vespa Enclave zone,
// similar to network_ipv4_cidr.
variable "network_ipv6_cidr" {
  description = "IPv6 CIDR for zone network"
  type        = string
  default     = "fd00:0:8000::/56"
  validation {
    condition = (
      # Valid CIDR (otherwise throw), and within fd00:0::/32
      startswith(cidrsubnet(var.network_ipv6_cidr, 0, 0), "fd00:0:") &&
      # Prefix length is 56
      try(tonumber(element(split("/", var.network_ipv6_cidr), 1)) == 56, false) &&
      # But not the subnet reserved for Network Prefix Translation on the hosts.
      cidrsubnet(var.network_ipv6_cidr, 0, 0) != "fd00:0::/56"
    )

    error_message = "CIDR for the IPv6 zone network must be a /56 subnet within fd00:0::/32, but not fd00:0::/56."
  }
}

locals {
  // Example for CIDR 10.128.0.0/16.  The first 16 bits defines the network prefix,
  // and the remaining bits will be used as follows:
  //     Bits:                 31  30 ...  16  15  14  13  12 ... 1  0
  //     Tenant host subnet:  [network prefix]  1 [         host part ]
  //     Bastion subnet:      [network prefix]  0   0   0 [ host part ]
  tenant_network_ipv4  = cidrsubnet(var.network_ipv4_cidr, 1, 1)
  bastion_network_ipv4 = cidrsubnet(var.network_ipv4_cidr, 3, 0)

  tenant_network_ipv6 = cidrsubnet(var.network_ipv6_cidr, 8, 2)
}
