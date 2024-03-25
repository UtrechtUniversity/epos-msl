#!/bin/bash
# copyright Utrecht University

set -e
set -x

sudo apt update

# Install Git if not present.
if ! command -v git >/dev/null; then
    echo "Installing Git."
    sudo apt install git -y
fi

# Install Ansible if not present.
if ! command -v ansible >/dev/null; then
    echo "Installing Ansible."
    sudo apt install ansible python3-pip -y
    sudo pip3 install --upgrade ansible==6.7.0
fi

# Remove current version.
rm -rf ~/epos-msl

# Clone epos-msl repository.
git clone https://github.com/UtrechtUniversity/epos-msl.git
cd epos-msl
git checkout development

# Set file permissions on SSH key to 0600.
chmod 0600 ~/epos-msl/vagrant/ssh/vagrant
