#!/bin/bash

key_path=$HOME/Documents/honey_net.pem

echo "Initializing terraform..."
terraform init
if [[ $? -eq 0 ]]; then
    echo "Initialized terraform."
else
    echo "Terraform already initialized."
fi

echo "Applying terraform..."
terraform apply -auto-approve
if [[ $? -eq 0 ]]; then
    echo "Terraform applied."
else
    echo "Terraform already applied."
fi

elk_server_public_ip=$(terraform output --raw elk_server_public_ip)
honeypot_server_public_ip=$(terraform output --raw honeypot_server_public_ip)

cat <<EOF > hosts.ini
[elk_server]
elk ansible_host=$elk_server_public_ip ansible_ssh_private_key_file=$key_path ansible_user=admin

[honeypot]
honey ansible_host=$honeypot_server_public_ip ansible_ssh_private_key_file=$key_path ansible_user=admin
EOF
echo "Created hosts.ini file."

while ! nc -z $elk_server_public_ip 22; do
    echo "Waiting for SSH on $elk_server_public_ip..."
    sleep 5
done

echo "Running ansible playbook..."
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i hosts.ini honey.yml
if [[ $? -eq 0 ]]; then
    echo "Ansible playbook ran successfully."
else
    echo "Ansible playbook failed."
fi
echo "Finished startup script."

echo "Elk server public IP: $elk_server_public_ip"
echo "Honeypot server public IP: $honeypot_server_public_ip"