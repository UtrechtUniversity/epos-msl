# EPOS-MSL catalog

This repository contains the [Docker Compose](https://docs.docker.com/compose/) setup for
the [EPOS-MSL metadata catalog](https://epos-msl.uu.nl/about), as well as the [Ansible](https://docs.ansible.com)
playbook for deploying the application to a server.

## Design

EPOS-MSL is based on [CKAN](https://www.ckan.org). It uses several modules / extensions to customize CKAN for the EPOS catalog.

### MSL CKAN extension

The [MSL CKAN core extension](https://github.com/UtrechtUniversity/msl_ckan_core) contains specific settings and configuration
for the EPOS MSL catalog.

### MSL CKAN Util extension

The [MSL CKAN util extension](https://github.com/UtrechtUniversity/msl_ckan_util) contains functionality used in the EPOS catalog
that can be reused in other catalogs, specifically custom facets and repeating fields.

## Requirements

### Requirements for local development (Docker setup)

* [Docker Compose](https://docs.docker.com/compose/)
* The images have been developed for the amd64 architecture

### Requirements for deploying to server

* [Ansible](https://docs.ansible.com/ansible/intro_installation.html) (>= 2.9)
* [Vagrant](https://www.vagrantup.com/docs/installation/) (2.x - only for local VM)
* Enterprise Linux 9 (e.g. AlmaLinux or RHEL)
* The images have been developed for the amd64 architecture

## Local development in containers (Docker)

If you use Windows, ensure that core.autocrlf is set to false in your git client before you clone the EPOS-MSL
repository: _git config --global core.autocrlf false_ Otherwise the Docker images may not work due to line
ending changes.

### Building the images

If you want to test any local updates, you need to re-build the images:

```
cd docker
./build-local-images.sh
```

### Running the application using Docker

First add an entry to your `/etc/hosts` file (or equivalent) so that queries for the development setup
interface resolve to your loopback interface. For example:

```
127.0.0.1 epos-msl.ckan
```

Unless you want to build the images locally (see above), you need to pull them from the registry:

```
cd docker
docker compose pull
```

Then start the Docker Compose setup:
```
docker compose up
```

Then wait until CKAN and MSL-API have started. This may take a couple of minutes. Navigate to
[https://epos-msl.ckan](https://epos-msl.ckan) in your browser. The development VM runs with
self-signed certificates, so you'll need to accept the security warning in your browser.

## Local development VM

First create the VMs using Vagrant:

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

Add the following host to /etc/hosts (GNU/Linux or macOS) or %SystemRoot%\System32\drivers\etc\hosts (Windows):
```
192.168.60.10 epos-msl.ckan
```

## MSL-API operations

### Seeding test admin panel account(s)

The MSL-API component contains a specific seeder for adding admin accounts. The account credentials can be
adjusted using the `epos_msl_admin_account_data` Ansible parameter. You need to run the UserSeeder to import
these accounts into MSL-API:

```bash
docker exec -it mslapi_web /bin/bash
cd /var/www/msl_api
sudo -u www-data php artisan db:seed --class=UserSeeder
```

You should now be able to login to the admin panel.


### Restarting the queue processor

After changing settings in the MSL-API .env file, please reload the configuration an restart the queue worker:

```bash
docker exec -it mslapi_web /bin/bash
cd /var/www/msl_api
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan queue:restart
```

### Sending a test email

In order to test the email settings, you can send a test email from MSL-API:

```bash
docker exec -it mslapi_web /bin/bash
cd /var/www/msl_api
sudo -u www-data php artisan app:test-mail some.email.address@organization.com
```

## Deploying the application to a server

In order to deploy the application to a server, create a custom Ansible configuration and
provide settings for the parameters listed in the section below.

### Configuration parameters

The main Ansible configuration parameters are:

|Setting                                 | Meaning                                                              |
|----------------------------------------|----------------------------------------------------------------------|
|epos_msl_ckan_database_password         | CKAN database password                                               |
|epos_msl_host_name                      | Hostname of the application that users connect to                    |
|epos_msl_host_ip                        | IP address that the application will run on                          |
|epos_msl_host_port                      | TCP port that the application will run on                            |
|epos_msl_mysql_root_password            | MySQL root password (MySQL is used for the MSL-API database)         |
|epos_msl_mslapi_db_password             | MSL-API database password                                            |
|epos_msl_fast_api_token                 | FastAPI token for MSL-API                                            |
|epos_msl_mta_role                       | Type of MTA: use mailpit for local setup; postfix for production     |
|epos_msl_postfix_relayhost_fqdn         | Postfix relay mail server name                                       |
|epos_msl_postfix_relayhost_port         | Postfix: TCP port of mail server to use                              |
|epos_msl_postfix_relayhost_username     | Postfix: username on relay mail server (if authentication enabled)   |
|epos_msl_postfix_relayhost_password     | Postfix: password on relay mail server (if authentication enabled)   |
|epos_msl_postfix_relayhost_auth_enabled | Postfix: enable authentication (yes/no, default: yes)                |
|epos_msl_postfix_relayhost_tls_enabled  | Postfix: whether to use TLS (yes/no, default: yes)                   |
|epos_msl_postfix_myhostname             | Postfix: own server name to send in EHLO/HELO messages               |
|epos_msl_postfix_origin                 | Postfix: origin domain                                               |
|epos_msl_mail_from_address              | Sender address to use for mail messages                              |
|epos_msl_cert_mode                      | Currently supported modes: selfsigned or static                      |
|epos_msl_static_cert                    | TLS certificate for reverse proxy (if static mode is selected)       |
|epos_msl_static_cert_key                | TLS certificate key for rev proxy (if static mode is selected)       |
|epos_msl_admin_account_data             | MSL-API admin accounts, in CSV format (name;email;password hash)     |

## License

This project is licensed under the GPL-v3 license.
The full license can be found in [LICENSE](LICENSE).
