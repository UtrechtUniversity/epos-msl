# epos-msl
[Ansible](https://docs.ansible.com) scripts for automatic deployment of the EPOS-MSL catalog.

## Requirements
### Control machine requirements
* [Ansible](https://docs.ansible.com/ansible/intro_installation.html) (>= 2.9)
* [VirtualBox](https://www.virtualbox.org/manual/ch02.html) (>= 5.1)
* [Vagrant](https://www.vagrantup.com/docs/installation/) (2.x)

### Managed node requirements
* [Ubuntu](https://www.ubuntu.com/) 20.04 LTS


## Local development VM

You can run the EPOS-MSL catalog locally in a development VM.

### Deploying the development VM

Create a virtual machine for the development environment:
```bash
vagrant up
```

On a Windows host, first SSH into the Ansible controller virtual machine (skip this step on GNU/Linux or macOS):
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

### Configuring shared folder for local development (Windows host)

For local development on the msl_api codebase a shared folder can be created and mounted within the server to work
with git and an IDE on the local filesystem.

1. Open the Virtualbox management program
2. Right-click the 'epos-msl' container and select settings
3. Go to 'shared folders' and click to add a new shared folder with the following settings:
   - name: epos
   - path: <path to local directory containing checkout of msl_api>
   - access: full
   - automatically connect: yes

Next ssh in to epos-msl:
```bash
vagrant ssh epos-msl
```
The share should now be visible within /media. To give the vagrant and msl-api users access to the folder and its
contents:
```bash
sudo adduser www-data vboxsf
sudo adduser vagrant vboxsf
```

Next, restart the server:
```bash
sudo restart
```

After rebooting ssh into epos-msl again and the content of the share should be visible within /media/sf_epos!

Now we will use the actual contents to replace the currently used checkout of msl_api by the contents of the share.
First remove the current msl_api folder or rename it:

```bash
sudo mv /var/www/msl_api /var/www/msl_api_bck
```

Create a symlink to use the contents from the shared folder to replace the msl_api folder:
```bash
sudo ln -s /media/sf_epos /var/www/msl_api
```

Check to see if the login page is accessible by navigating to https://epos-msl.ckan.test/webservice/login. A reboot might be
needed.

### Seeding test admin panel account(s)

The msl_api project contains a specific seeder for adding test admin accounts. Contents can be adjusted to add or
adjust accounts within /database/seeders/AdminUserSeeder.php. Add the account(s) by running the following command:

```bash
sudo -u www-data /usr/bin/php8.0 artisan db:seed --class=AdminUserSeeder
```

You should now be able to login to the admin panel.


### Upgrading EPOS-MSL instance
Upgrading the EPOS-MSL development instance to the latest version can be done by running the Ansible playbooks again.

On a Windows host first SSH into the Ansible controller virtual machine (skip this step on GNU/Linux or macOS):
```bash
vagrant ssh epos-msl-controller
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

### Create and set CKAN apikey for msl_api connections

An API key needs to be generated within CKAN to be used by msl-api for transferring data.

1. Navigate to: https://epos-msl.ckan.test/user/login and sign in in with the following credentials:

```
   Username: ckanadmin
   Password: testtest
```

2. Navigate to: https://epos-msl.ckan.test/user/edit/ckanadmin and click 'Regenerate API key'
3. Copy the API Key displayed in the bottom left
4. Paste the value within the .env file of msl-api for the 'CKAN_API_TOKEN' key

### Restarting the queue processor

After changing settings in the .env file or making changes to the code used by queue processing jobs the queue needs to
be restarted using:

```bash
sudo -u www-data /usr/bin/php8.0 artisan queue:restart
```

## Updating the MSL API app key

If you have deployed the server using the default empty MSL API app key, generate
a random one:

```
sudo -u www-data /usr/bin/php8.0 artisan key:generate
sudo -u www-data /usr/bin/php8.0 artisan config:cache
```

Then copy this key from `APP_KEY` in `/var/www/msl_api/.env` to the Ansible configuration of
the server.


## Database creation/seeding for the MSL API

You currently need to manually trigger creation and seeding of the MSL API database, as well as linking its storage
space.

Run the following commands in /var/www/msl\_api after deploying the application using Ansible:

```bash
sudo -u www-data /usr/bin/php8.0 artisan migrate
sudo -u www-data /usr/bin/php8.0 artisan db:seed
sudo -u www-data /usr/bin/php8.0 artisan storage:link
```

## Configuration

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
|msl_api_app_key           | the MSL API application key. The current way to configure this is to deploy the application, generate the app key by running `sudo -u www-data /usr/bin/php8.0 artisan key:generate && sudo -u www-data /usr/bin/php8.0 artisan config:cache` in /var/www/msl\_api. Finally copy the generated key in /var/www/msl\_api/.env to the host\_vars file.
| ckan_install_spatial_plugin | whether to install the ckanext-spatial plugin (default: false) |
| ckan_spatial_plugin_repo    | Github repository to use for the ckanext-spatial plugin |
| ckan_spatial_plugin_version | Branch or tag to use for the ckanext-spatial plugin |

## CKAN catalog

EPOS-MSL is based on [CKAN](https://www.ckan.org). It uses several modules / extensions to customize CKAN for the EPOS catalog.

### MSL CKAN extension

The [MSL CKAN core extension](https://github.com/UtrechtUniversity/msl_ckan_core) contains specific settings and configuration
for the EPOS MSL catalog.

### MSL CKAN Util extension

The [MSL CKAN util extension](https://github.com/UtrechtUniversity/msl_ckan_util) contains functionality used in the EPOS catalog
that can be reused in other catalogs, specifically custom facets and repeating fields.

## License
This project is licensed under the GPL-v3 license.
The full license can be found in [LICENSE](LICENSE).
