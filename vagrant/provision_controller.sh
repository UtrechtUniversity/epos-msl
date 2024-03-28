#!/bin/bash
# copyright Utrecht University

set -e
set -x

# Configure VM to use Google DNS servers - the default configuration
# does not work reliably on Windows.

cat << RESOLVEDCONF > resolved.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See resolved.conf(5) for details

[Resolve]
DNS=8.8.8.8
FallbackDNS=8.8.4.4
#Domains=
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#DNSOverTLS=no
#Cache=no-negative
#DNSStubListener=yes
#ReadEtcHosts=yes
RESOLVEDCONF

sudo cp resolved.conf /etc/systemd
sudo systemctl restart systemd-resolved

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
