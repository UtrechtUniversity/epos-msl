#!/bin/bash
# copyright Utrecht University

# Install Git if not present.
if ! command -v git >/dev/null; then
    echo "Installing Git."
    sudo yum install git -y
fi

# Install Ansible if not present.
if ! command -v ansible >/dev/null; then
    echo "Installing Ansible."
    sudo yum install epel-release -y
    sudo yum install ansible -y
fi

# Run EPOS-MSL playbook.
#cd /vagrant
#sudo chmod 0644 /vagrant/vagrant/ssh/vagrant

#ansible-playbook playbook.yml
