# Tailscale policy and auth key for the subnet router.

resource "tailscale_tailnet_key" "router_auth_key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  description   = "Infrastructure key for Toronto Subnet Router"
  tags          = ["tag:subnet-router"]

  depends_on = [tailscale_acl.global_policy]

  lifecycle {
    ignore_changes = [expiry]
  }
}


resource "tailscale_acl" "global_policy" {
  overwrite_existing_content = true

  acl = <<EOF
{
  "tagOwners": {
    "tag:subnet-router": ["autogroup:admin"]
  },

  "grants": [
    {
      "src":    ["autogroup:admin"],
      "dst":    ["tag:subnet-router"],
      "ip":     ["22"]
    },
    {
      "src":    ["autogroup:member"],
      "dst":    ["10.0.2.0/24"],
      "ip":     ["*"]
    }
  ],

  "ssh": [
    {
      "action": "accept",
      "src":    ["autogroup:admin"],
      "dst":    ["tag:subnet-router"],
      "users":  ["root"]
    }
  ],

  // Auto-approve the route advertised by the tagged router.
  "autoApprovers": {
    "routes": {
      "10.0.2.0/24": ["tag:subnet-router"]
    }
  }
}
EOF
}
