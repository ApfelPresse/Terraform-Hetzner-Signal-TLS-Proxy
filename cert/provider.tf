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

data "terraform_remote_state" "bootstrap" {
  backend = "local"

  config = {
    path = "${path.module}/../bootstrap/terraform.tfstate"
  }
}

locals {
  ssh_username = data.terraform_remote_state.bootstrap.outputs.ssh_username
  ssh_port = data.terraform_remote_state.bootstrap.outputs.ssh_port
  server_ip = data.terraform_remote_state.bootstrap.outputs.server_ip
  private_ssh_key = data.terraform_remote_state.bootstrap.outputs.private_ssh_key
}