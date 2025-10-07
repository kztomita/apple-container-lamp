# Overview

A sample script to create a LAMP (Linux, Apache, MySQL, PHP) stack configuration with Nginx, PHP-FPM, and MySQL using Apple Container.

Since Apple Container doesn't have compose functionality yet, this shell script allows you to create resources and containers together.

# Prerequisites

<a href="https://github.com/apple/container">Apple Container</a> should be installed and the service should be running.

The Container version used is v0.4.1.

```
% container --version
container CLI version 0.4.1 (build: release, commit: 4ac18b5)
```

# Setup

To enable container-to-container communication using hostnames, you need to create a DNS server and set it as default.

```
% sudo container system dns create box
% container system dns default set box
```

This allows container-to-container communication to be accessed via `<container-name>.box`.

If you want to use an existing domain name in your environment, you need to modify the following files:

- fastcgi_pass setting in ./nginx-container/conf.d/default.conf (lamp-php.box:9000)
- DNS_DEFAULT_NAME=box setting in ./app.sh
- DB hostname specified in ./html/db.php (lamp-mysql.box)

# How to Start
```
% ./app.sh create
```
This creates a volume for the MySQL container.

```
% ./app.sh build
```

Build the image.
This builds the PHP-FPM container image.

```
% ./app.sh run
```

Start the containers.
Three containers (Nginx, PHP-FPM, MySQL) will start.

```
% container ls
ID          IMAGE                                               OS     ARCH   STATE    ADDR
buildkit    ghcr.io/apple/container-builder-shim/builder:0.6.0  linux  arm64  running  192.168.64.23
lamp-nginx  docker.io/library/nginx:latest                      linux  arm64  running  192.168.64.182
lamp-mysql  docker.io/library/mysql:latest                      linux  arm64  running  192.168.64.183
lamp-php    lamp-php:latest                                     linux  arm64  running  192.168.64.181
```

# Accessing Containers
```
% curl http://localhost:8080
This is index.html.
```
You can access like this.

```
curl http://lamp-nginx.box/
```
You can also directly access containers using hostname.

Test PHP script execution:
```
curl http://localhost:8080/test.php
```

Test database connection:
```
curl http://localhost:8080/db.php
```

# Other Commands

## Stop Containers
```
% ./app.sh stop
```
Stop the three containers (Nginx, PHP-FPM, MySQL) using container stop.

## Start Containers
```
% ./app.sh start
```

Start the three containers using container start.

When you modify Nginx config (nginx-container/conf.d/default.conf), apply changes with:
```
% ./app.sh stop
% ./app.sh start
```

## Remove Containers
```
% ./app.sh cleanup_container
```

This doesn't delete volumes and other resources.

If you want to change container run arguments, modify the run() function in app.sh, then:
```
% ./app.sh cleanup_container
% ./app.sh run
```
to recreate the containers.

## Cleanup

```
% ./app.sh cleanup
```

Remove all created containers and resources.

- Stop and remove the three containers
- Remove images built with ./app.sh build
- Remove volumes created with ./app.sh create

# Directory Structure

**./html**

Volume that serves as DocumentRoot.<br />
Bind mounted from Nginx and PHP-FPM containers.

**./nginx-container/conf.d**

Bound to /etc/nginx/conf.d in the Nginx container.<br />
Place Nginx configuration files here.

**./php-container/Dockerfile**

Dockerfile for building the PHP-FPM container image.<br />
Built with ./app.sh build.

**./php-container/php.ini**

Place PHP configuration files here.<br />
php.ini is copied into the image during image build.

**./php-container/docker-php-ext-xdebug.ini**

Copy this file into the image when using xdebug.<br />
You may need to adjust xdebug.client_host depending on the container's network settings.

**./mysql-container/docker-entrypoint-initdb.d/init.sql**

SQL for MySQL container database initialization.
