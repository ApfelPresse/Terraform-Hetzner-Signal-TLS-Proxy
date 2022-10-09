#!/usr/bin/env bash

key_file="$HOME/.signal_server_pem"

#info "setting up key_file ... "
terraform output private_ssh_key >"$key_file"
chmod 0600 "$key_file"
if [[ $(uname) == "Darwin" ]]; then
  # see https://stackoverflow.com/a/28592208
  sed -i "" "s/<<EOT//g; s/EOT//g" "$key_file"
else
  sed -i "s/<<EOT//g; s/EOT//g" "$key_file"
fi

ip=$(terraform output -json server_ip | jq -r '.')
ssh_username=$(terraform output -json ssh_username | jq -r '.')
ssh_port=$(terraform output -json ssh_port | jq -r '.')

ssh -q -o "StrictHostKeyChecking no" -i "$key_file" "$ssh_username"@"$ip" -p"$ssh_port" "$@"