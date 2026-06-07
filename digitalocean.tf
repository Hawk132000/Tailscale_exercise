# DigitalOcean VPC, subnet router, and private backend.

# Private network for the lab.
resource "digitalocean_vpc" "subnet_vpc" {
  name     = "ts-poc-vpc-toronto"
  region   = "tor1"
  ip_range = "10.0.2.0/24"
}

# Gateway that joins Tailscale and advertises the VPC route.
resource "digitalocean_droplet" "subnet_router" {
  name     = "ts-subnet-router"
  region   = "tor1"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.subnet_vpc.id

  user_data = templatefile("${path.module}/cloud-config.yaml", {
    tailscale_key = tailscale_tailnet_key.router_auth_key.key
  })
}

# Backend target. No Tailscale agent is installed here.
resource "digitalocean_droplet" "backend_target" {
  name     = "ts-corporate-private-backend-app"
  region   = "tor1"
  size     = "s-1vcpu-1gb"
  image    = "ubuntu-24-04-x64"
  vpc_uuid = digitalocean_vpc.subnet_vpc.id

  depends_on = [digitalocean_droplet.subnet_router]
}

# Only allow inbound traffic that arrives from the VPC.
resource "digitalocean_firewall" "backend_isolation" {
  name        = "vpc-only-isolation-firewall"
  droplet_ids = [digitalocean_droplet.backend_target.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1-65535"
    source_addresses = [digitalocean_vpc.subnet_vpc.ip_range]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1-65535"
    source_addresses = [digitalocean_vpc.subnet_vpc.ip_range]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = [digitalocean_vpc.subnet_vpc.ip_range]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "router_public_ip" {
  value       = digitalocean_droplet.subnet_router.ipv4_address
  description = "Public IP of the subnet router."
}

output "backend_private_ip" {
  value       = digitalocean_droplet.backend_target.ipv4_address_private
  description = "Private VPC IP of the backend target."
}
