# EPOS-MSL Docker development setup

This Docker setup currently has an experimental status, and is in development.

## Building the images

The images of the EPOS-MSL are not yet available in a registry, so you'll have to build them locally first.

```
./build-local-images.sh
```

## Using the Docker setup

First add an entry to your `/etc/hosts` file (or equivalent) so that queries for the development setup
interface resolve to your loopback interface. For example:

```
127.0.0.1 epos-msl.ckan
```

Start the Docker Compose setup:
```
docker compose up
```

Wait until CKAN has started. Then navigate to [https://epos-msl.ckan](https://epos-msl.ckan) in your browser. The
development VM runs with self-signed certificates, so you'll need to accept the security warning.
