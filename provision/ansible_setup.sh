#!/bin/bash
echo ">>> Installing Ansible and Python dependencies..."

sudo apt update
sudo apt install -y software-properties-common python3 python3-pip python3-venv git

sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

pip3 install --upgrade pip
pip3 install docker

echo ">>> Ansible setup complete."