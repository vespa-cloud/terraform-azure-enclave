variable "zone" {
    description = "Vespa Cloud zone to bootstrap"
    type = object({
        name             = string, // The Vespa Cloud zone name, e.g. prod.azure-eastus-az1
        short_name       = string, // The Vespa Cloud short name used in e.g. hostnames, e.g. prod.eastus-az1
        environment      = string, // The Vespa Cloud environment, e.g. prod
        region           = string, // The Vespa Cloud region, e.g. azure-eastus-az1
        azure_region     = string, // The Azure region, e.g. eastus
        physical_zone    = string, // The physical (availability) zone, e.g. eastus-az1
        template_version = string,
    })
}

variable "network_ipv4_cidr" {
    description = "IPv4 CIDR for zone network"
    type        = string
    default     = "10.128.0.0/16"
    validation {
        condition = (
                # Valid CIDR (otherwise throw), and within 10.0.0.0/8
                startswith(cidrsubnet(var.network_ipv4_cidr, 0, 0), "10.") &&
                # Prefix length is 16
                try(tonumber(element(split("/", var.network_ipv4_cidr), 1)) == 16, false)
        )

        error_message = "CIDR for the IPv4 zone network must be /16 and must be within 10.0.0.0/8"
    }
}

variable "network_ipv6_cidr" {
    description = "IPv6 CIDR for zone network"
    type        = string
    default     = "fd00:0:8000::/48"
    validation {
        condition = (
                # Valid CIDR (otherwise throw), and within fd00:0::/32
                startswith(cidrsubnet(var.network_ipv6_cidr, 0, 0), "fd00:0:") &&
                # Prefix length is 48
                try(tonumber(element(split("/", var.network_ipv6_cidr), 1)) == 48, false) &&
                # But not the subnet reserved for Network Prefix Translation on the hosts.
                cidrsubnet(var.network_ipv6_cidr, 0, 0) != "fd00:0::/48"
        )

        error_message = "CIDR for the IPv6 zone network must be a /48 subnet within fd00:0::/32, but not fd00:0::/48."
    }
}
