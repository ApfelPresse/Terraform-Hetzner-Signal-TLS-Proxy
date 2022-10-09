provider "hcloud" {
  token = var.hcloud_api_token
}

terraform {
  required_providers {
    hcloud  = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.35.2"
    }
  }
}
