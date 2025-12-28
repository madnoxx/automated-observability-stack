#!/bin/bash
set -e

sudo apt update
sudo apt install -y \
  build-essential \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libffi-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  liblzma-dev \
  curl \
  git \
  ca-certificates \
  software-properties-common \
  python3-venv \
  docker.io

sudo usermod -aG docker $USER

PYTHON_VERSION=3.10.14

cd /usr/src
sudo curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
sudo tar xzf Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}

sudo ./configure --enable-optimizations
sudo make -j"$(nproc)"
sudo make altinstall

cd ~
/usr/local/bin/python3.10 -m venv ansible_venv_py310

sudo chown -R vagrant:vagrant /home/vagrant/ansible_venv_py310

source ~/ansible_venv_py310/bin/activate

pip install --upgrade pip setuptools wheel

pip install --upgrade \
  ansible-core \
  ansible \
  molecule \
  molecule-docker \
  ansible-compat

ansible-galaxy collection install \
  community.docker \
  ansible.posix

ansible --version
molecule --version
docker --version
python --version
