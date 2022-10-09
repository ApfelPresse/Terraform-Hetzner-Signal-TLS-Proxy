#!/bin/bash
set -eu

apt-get -qq update
apt-get -qq install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    jq \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   edge stable"
apt-get -qq update && apt-get -qq install -y docker.ce docker-compose-plugin

cat > /etc/docker/daemon.json <<EOF
{
  "dns": ["8.8.8.8", "1.1.1.1", "8.8.4.4"]
}
EOF

cat >> /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl restart docker.service