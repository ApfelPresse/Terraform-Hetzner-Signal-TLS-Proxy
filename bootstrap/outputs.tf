output "ssh_username" {
  value = local.ssh_username
}

output "ssh_port" {
  value = local.ssh_port
}

output "server_ip" {
  value = hcloud_server.server.ipv4_address
}

output "private_ssh_key" {
  sensitive = true
  value     = tls_private_key.signal.private_key_pem
}