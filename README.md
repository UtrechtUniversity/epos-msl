# epos-msl
[Ansible](https://docs.ansible.com) scripts for automatic deployment of EPOS-MSL.

## Requirements
### Control machine requirements
* [Ansible](https://docs.ansible.com/ansible/intro_installation.html) (>= 2.9)
* [VirtualBox](https://www.virtualbox.org/manual/ch02.html) (>= 5.1)
* [Vagrant](https://www.vagrantup.com/docs/installation/) (2.x)

### Managed node requirements
* [Ubuntu](https://www.ubuntu.com/) 20.04 LTS

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

## Database creation/seeding for the MSL API

You currently need to manually trigger creation and seeding of the MSL API database, as well as linking its storage
space.

Run the following commands in /var/www/msl\_api after deploying the application using Ansible:

```bash
sudo -u www-data /usr/bin/php8.0 artisan migrate
sudo -u www-data /usr/bin/php8.0 artisan db:seed
sudo -u www-data /usr/bin/php8.0 artisan storage:link
```

# Configuration

The main configuration settings are:

|Settingi       | Meaning       |
| ------------- |:-------------:|
|epos_msl_fqdn             | fully qualified domain name (FQDN) of the catalog, e.g. epos-catalog.mydomain.nl |
|ckan_database_password    | password for the CKAN database (can be randomly generated with e.g. pwgen -n 16) |
|ckan_admin_password       | password for the ckanadmin account (can be randomly generated with e.g. pwgen -n 16) |
|msl_api_database_password | password for the MSL API database (can be randomly generated with e.g. pwgen -n 16) |
|msl_api_app_url           | application URL for the MSL API web service, e.g. https://epos-catalog.mydomain.nl/webservice |
|msl_api_asset_url         | asset URL for the MSL API web service, e.g. https://epos-catalog.mydomain.nl/webservice |
|ckan_api_token            | the MSL API uses this value to authenticate to the CKAN API. this should currently be the API key (not API token!) of the ckanadmin account. The current way to use this field is: deploy the catalog using a dummy value for this parameter, log in on CKAN using the ckanadmin account, generate an API key, replace the dummy value in the host\_vars file with the real API key, and run the playbook a second time.
|msl_api_app_key           | the MSL API application key. The current way to configure this is to deploy the application, generate the app key by running `/usr/bin/php8.0 artisan key:generate` in /var/www/msl\_api. Finally copy the generated key in /var/www/msl\_api/.env to the host\_vars file.

# CKAN catalog

EPOS-MSL is based on [CKAN](https://www.ckan.org). It uses several modules / extensions to customize CKAN for the EPOS catalog.

## MSL CKAN extension

The [MSL CKAN core extension](https://github.com/UtrechtUniversity/msl_ckan_core) contains specific settings and configuration
for the EPOS MSL catalog.

## MSL CKAN Util extension

The [MSL CKAN util extension](https://github.com/UtrechtUniversity/msl_ckan_util) contains functionality used in the EPOS catalog
that can be reused in other catalogs, specifically custom facets and repeating fields.

## License
This project is licensed under the GPL-v3 license.
The full license can be found in [LICENSE](LICENSE).
