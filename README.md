# epos-msl
[Ansible](https://docs.ansible.com) scripts for automatic deployment of EPOS-MSL.

## Requirements
### Control machine requirements
* [Ansible](https://docs.ansible.com/ansible/intro_installation.html) (>= 2.4)
* [VirtualBox](https://www.virtualbox.org/manual/ch02.html) (>= 5.1)
* [Vagrant](https://www.vagrantup.com/docs/installation/) (>= 1.9)

### Managed node requirements
* [CentOS](https://www.centos.org/) (>= 7.3)

## Deploying EPOS-MSL development instance

Configure the virtual machine for development:
```bash
vagrant up
```

On a Windows host first SSH into the Ansible controller virtual machine (skip this step on GNU/Linux or macOS):
```bash
vagrant ssh epos-msl-controller
cd ~/epos-msl
```

Deploy EPOS-MSL to development virtual machine:
```bash
ansible-playbook playbook.yml
```

Add following host to /etc/hosts (GNU/Linux or macOS) or %SystemRoot%\System32\drivers\etc\hosts (Windows):
```
192.168.60.10 epos-msl.ckan.test
```

## Upgrading EPOS-MSL instance
Upgrading the EPOS-MSL development instance to the latest version can be done by running the Ansible playbooks again.

On a Windows host first SSH into the Ansible controller virtual machine (skip this step on GNU/Linux or macOS):
```bash
vagrant ssh controller
cd ~/epos-msl
```

Upgrade Ansible scripts:
```bash
git pull
```

Upgrade EPOS-MSL instance:
```bash
ansible-playbook playbook.yml
```

## License
This project is licensed under the GPL-v3 license.
The full license can be found in [LICENSE](LICENSE).
