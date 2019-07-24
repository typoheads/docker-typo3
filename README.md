# Docker + TYPO3

Simple docker setup for TYPO3. Use it for development and production.

-----


## Quickstart


```bash
git clone https://github.com/typoheads/docker-typo3.git && cd docker-typo3
composer install
chown -R www-data:www-data public/ var/
docker-compose up -d
```


## Goals

Quickly spin up a working TYPO3 setup with `composer` and `docker-compose` and - when needed - add other docker services like `traefik`, `solr` or `smtp` to your stack. This project uses [typo3-apache-php](https://hub.docker.com/r/typoheads/typo3-apache-php) as a base image - a well-prepared and simple docker image for TYPO3 by including only the minimal requirements.

The approach of this project is to avoid a bloated and opiniated `docker-compose.yml`-file, because requirements are different from project to project. You can clone this repo and test the different combinations of the provided `docker-compose`-files as described below an then adjust `docker-compose.yml` to your specific requirements. 

The basic idea for the development-workflow is to develop while having all files locally easily at hand, be it on your local machine or a dedicated linux machine for development purposes. Files are bind-mounted into the corresponding docker containers. When the project is ready for production or a new release is planned, then adjust the provided `Dockerfile` and `docker build .` a docker image. Your files and setup will be included automatically in the resulting image (excluding mysql data of course). After build, push the image to a registry and run it on your production system. 

## TYPO3 Basic

Brings up a basic TYPO3 installation.

```bash
git clone https://github.com/typoheads/docker-typo3.git && cd docker-typo3
composer install
chown -R www-data:www-data public/ var/
docker-compose up -d
```

## TYPO3 + Proxy/Let's Encrypt

Brings up TYPO3 behind a proxy together with Let's Encrypt cert generation, uses [traefik](https://blog.containo.us/back-to-traefik-2-0-2f9aa17be305).
Prerequisites: 

1. Point a domain to your host
2. Adjust label `<YOUR_DOMAIN>` in `docker-compose-traefik.yml`


```bash
git clone https://github.com/typoheads/docker-typo3.git && cd docker-typo3
composer install
chown -R www-data:www-data public/ var/
touch docker/traefik/acme.json
chmod 600 docker/traefik/acme.json
docker network create proxy2
docker-compose -f docker-compose-traefik.yml up -d
```

Note: Unfortunately TYPO3 *needs the IP of the proxy* in its configuration. As of the time of writing (Jul 2019) a hostname is *not* allowed, therefore you need to do the following:

* Do `docker inspect <traefik-container>` and copy the `IPAddress` 
* Insert fixed IP with `ipv4_address` in `docker-compose-traefik.yml`
* Add IP to `AdditionalConfiguration.php`:

```php
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyIP'] = '<IP_OF_PROXY_CONTAINER>';
```

## TYPO3 + Solr

Spins up TYPO3 together with a solr server, uses [official solr image](https://hub.docker.com/_/solr/). 

```bash
git clone https://github.com/typoheads/docker-typo3.git && cd docker-typo3
composer install
composer require apache-solr-for-typo3/solr
chown -R www-data:www-data public/ var/
docker-compose -f docker-compose-solr.yml up -d
```


## TYPO3 + SMTP

Brings up TYPO3 together with a simple SMTP-server, uses [mailhog image](https://hub.docker.com/r/mailhog/mailhog).


```bash
git clone https://github.com/typoheads/docker-typo3.git && cd docker-typo3
composer install
chown -R www-data:www-data public/ var/
docker-compose -f docker-compose-mailhog.yml up -d
```


* Configure TYPO3 in `AdditionalConfiguration.php`: 

```php
$GLOBALS['TYPO3_CONF_VARS']['MAIL']['transport'] = 'smtp';
$GLOBALS['TYPO3_CONF_VARS']['MAIL']['transport_smtp_server'] = '<NAME_OF_SMTP_CONTAINER>';
```


## Advanced configuration

Finetune your installation by adjusting the included configuration files in `./docker`. Mount any of them into the corresponding container to take effect. 

### Apache / PHP

* Configuration file(s): `docker/apache`, `docker/php`, `docker/mod_pagespeed`
* Add to `docker-compose.yml`:

```yaml
volumes:
 - ./conf/apache/apache2.conf:/etc/apache2/apache2.conf
 - ./conf/apache/000-default.conf:/etc/apache2/sites-available/000-default.conf
 - ./conf/php/php.ini:/usr/local/etc/php/conf.d/php.ini
```

* Installation of mod_pagespeed in `Dockerfile`

```yaml
RUN cd /tmp && \
    curl -o /tmp/mod-pagespeed.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i /tmp/mod-pagespeed.deb && \
    apt-get -f install && \
    chown -R www-data:www-data /var/cache/mod_pagespeed/

COPY docker/mod_pagespeed/pagespeed.conf /etc/apache2/mods-available/
```

Note: the included pagespeed configuration is battle tested, but highly opiniated. It will need adjustments based on your project requirements. In your final deployment, use volumes for the directories `/var/cache/mod_pagespeed` and `/var/log/pagespeed`. 


### MySQL

* Configuration file(s): `docker/mysql`
* Add to `docker-compose.yml`:

```yaml
volumes:
 - ./conf/mysql:/etc/mysql/conf.d
```

### Traefik

* Configuration file(s): `docker/traefik`

Use Let's Encrypt's staging server while adjusting DNS to get things right before running up against rate limits.

```
caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
```

### Git

Preserve essential TYPO3 files via `.gitignore` when comitting:

```
!public/typo3conf/
public/typo3conf/*
!public/typo3conf/AdditionalConfiguration.php
!public/typo3conf/LocalConfiguration.php
```

## Ready for production?

A multistage `Dockerfile` is used to build the final docker image. It's highly recommended to adjust it to your needs, e.g. [by adding php packages](https://github.com/typoheads/typo3-apache-php), or finetuning configuration files etc. 

```bash
docker build .
```

Note: if you require packages from a private repository (via vcs or packagist) you'll need to uncomment the corresponding block in the `Dockerfile` and present your key during buildtime:

```bash
docker build -t your-image-name:tag \
             --build-arg SSH_PRIVATE_KEY="$(cat /root/.ssh/id_rsa)" \
             --build-arg KNOWN_HOSTS="$(cat /root/.ssh/known_hosts)" --no-cache .
```

After build, push the image to your registry and pull the new release from production system.

