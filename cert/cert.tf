resource "null_resource" "create_cert" {

  connection {
    host        = local.server_ip
    timeout     = "2m"
    port        = local.ssh_port
    user        = local.ssh_username
    private_key = local.private_ssh_key
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "docker compose -f docker-compose-test.yml down",
      "cd Signal-TLS-Proxy",
      "export data_path=\"./data/certbot\"",
      "if [ -d \"$data_path\" ]; then echo \"Certificate found, skip!\" && exit 0; fi",
      "docker compose down",
      "sudo mkdir -p \"$data_path/conf\"",
      "sudo chown -R ${local.ssh_username} /home/${local.ssh_username}",
      "docker-compose run -p 80:80 --rm --entrypoint 'sh -c \"certbot certonly --standalone --register-unsafely-without-email -d ${var.domain} --agree-tos --force-renewal && ln -fs /etc/letsencrypt/live/${var.domain}/ /etc/letsencrypt/active\"' certbot",
      "curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > \"$data_path/conf/options-ssl-nginx.conf\"",
      "curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > \"$data_path/conf/ssl-dhparams.pem\"",
      "docker compose up -d"
    ]
  }

  triggers = {
    always = timestamp()
  }
}