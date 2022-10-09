locals {
  ssh_port     = random_integer.ssh_port.id
  ssh_username = random_pet.username.id
}

resource "random_pet" "username" {
  length    = 1
  separator = "_"
}

resource "random_integer" "ssh_port" {
  min = 2000
  max = 65000
}

resource "tls_private_key" "signal" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "signal" {
  name       = "signal_ssh_key"
  public_key = tls_private_key.signal.public_key_openssh
}

resource "hcloud_server" "server" {
  name        = "signal"
  location    = "nbg1"
  image       = "ubuntu-20.04"
  server_type = "cx11"
  user_data   = data.template_file.user_data.rendered

  firewall_ids = [hcloud_firewall.firewall.id]

  connection {
    host        = self.ipv4_address
    timeout     = "2m"
    port        = local.ssh_port
    user        = local.ssh_username
    private_key = tls_private_key.signal.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "echo ready!"
    ]
  }
}

data "template_file" "user_data" {
  template = file("user_data.yml")
  vars     = {
    SSH_PORT     = local.ssh_port
    SSH_USERNAME = local.ssh_username
    SSH_KEY      = hcloud_ssh_key.signal.public_key
  }
}

data "http" "my_public_ip_data" {
  url             = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "hcloud_firewall" "firewall" {
  name = "signal"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = local.ssh_port
    source_ips = [
      "${jsondecode(data.http.my_public_ip_data.response_body).ip}/32"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 80
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 8080
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "null_resource" "bootstrap" {

  connection {
    host        = hcloud_server.server.ipv4_address
    timeout     = "2m"
    port        = local.ssh_port
    user        = local.ssh_username
    private_key = tls_private_key.signal.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt -y install unattended-upgrades git",
      "echo 'unattended-upgrades       unattended-upgrades/enable_auto_updates boolean true' | sudo debconf-set-selections; sudo dpkg-reconfigure -f noninteractive unattended-upgrades",
      "git clone https://github.com/signalapp/Signal-TLS-Proxy.git",
      "cd Signal-TLS-Proxy && git checkout ac94d6b869f942ec05d7ef76840287a1d1f487f9"
    ]
  }
}

resource "null_resource" "install_docker" {

  connection {
    host        = hcloud_server.server.ipv4_address
    timeout     = "2m"
    port        = local.ssh_port
    user        = local.ssh_username
    private_key = tls_private_key.signal.private_key_pem
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/home/${local.ssh_username}/bootstrap.sh"
  }

  provisioner "file" {
    source      = "docker-compose-test.yml"
    destination = "/home/${local.ssh_username}/docker-compose-test.yml"
  }

  provisioner "file" {
    source      = "docker-compose"
    destination = "/home/${local.ssh_username}/docker-compose"
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "sudo mv docker-compose /usr/bin/docker-compose",
      "sudo chown ${local.ssh_username} /usr/bin/docker-compose",
      "sudo chmod +x /usr/bin/docker-compose",
      "sudo bash /home/${local.ssh_username}/bootstrap.sh",
      "sudo usermod -aG docker ${local.ssh_username}",
    ]
  }

  triggers = {
    dir_shar = sha1(join("", [filesha1("bootstrap.sh"), filesha1("docker-compose-test.yml")]))
  }

  depends_on = [
    null_resource.bootstrap
  ]
}

resource "null_resource" "test_docker" {

  connection {
    host        = hcloud_server.server.ipv4_address
    timeout     = "2m"
    port        = local.ssh_port
    user        = local.ssh_username
    private_key = tls_private_key.signal.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "docker-compose -f docker-compose-test.yml up -d",
      "docker ps",
    ]
  }

  depends_on = [
    null_resource.install_docker
  ]
}