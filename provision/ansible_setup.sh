#!/bin/bash
set -e

apt update
apt install -y \
  python3 \
  python3-venv \
  python3-pip \
  git \
  curl \
  unzip \
  ca-certificates \
  software-properties-common \

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

usermod -aG docker vagrant 

sudo -u vagrant -i bash << 'EOF'
    python3 -m venv ~/ansible_venv
    
    source ~/ansible_venv/bin/activate
    
    pip install --upgrade pip setuptools wheel
    
    pip install --upgrade \
      ansible-core \
      molecule \
      molecule-docker \
      ansible-compat \
      docker # Python SDK для Docker тоже нужен!

    ansible-galaxy collection install community.docker ansible.posix
    
    if ! grep -q "ansible_venv" ~/.bashrc; then
        echo "source ~/ansible_venv/bin/activate" >> ~/.bashrc
    fi

    mkdir -p /home/vagrant/.ssh
    chmod 700 /home/vagrant/.ssh

    if ls /vagrant/monitoring-ansible/id_rsa_* 1> /dev/null 2>&1; then
        cp /vagrant/monitoring-ansible/id_rsa_* ~/.ssh/
        chmod 600 ~/.ssh/id_rsa_*
        echo "SSH keys copied successfully."
    else
        echo "WARNING: No SSH keys found in /vagrant/monitoring-ansible/"
    fi

    echo "StrictHostKeyChecking no" >> /home/vagrant/.ssh/config
    chmod 600 /home/vagrant/.ssh/config
EOF