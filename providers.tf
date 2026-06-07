# ==============================================================================
# PROVIDERS CONFIGURATION
# Initializes cloud providers and locks versions to ensure deployment stability.
#
# Note: Authentication tokens are securely read from your local environment 
# variables (DIGITALOCEAN_TOKEN, TAILSCALE_OAUTH_CLIENT_ID, etc.) so that 
# secrets are never hardcoded or committed to version control.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.87.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29.2"
    }
  }
}

provider "digitalocean" {}
provider "tailscale" {}