#!/bin/bash

MYSQL_VOLUME=lamp-mysqlvol
DOCROOT_VOLUME=lamp-docroot

MYSQL_CONTAINER_NAME=lamp-mysql
MYSQL_IMAGE=mysql:latest
MYSQL_ROOT_PASSWORD=root

NGINX_CONTAINER_NAME=lamp-nginx
NGINX_IMAGE=nginx:latest

PHP_CONTAINER_NAME=lamp-php
PHP_BUILDED_IMAGE=lamp-php:latest

source ./common.sh

# Create necessary resources
create() {
    volume_create $MYSQL_VOLUME
}

# Delete created resources.
cleanup() {
    cleanup_container
    volume_delete $MYSQL_VOLUME
    image_rm $PHP_BUILDED_IMAGE
}

build() {
    container build --tag $PHP_BUILDED_IMAGE --file ./php-container/Dockerfile
}

run() {
    local CWD=$(pwd)
    local NGINX_CONFDIR=$CWD/nginx-container/conf.d
    local DOCROOT=$CWD/html
    local PHP_INI=$CWD/php-container/php.ini
    local MYSQL_INITDB=$CWD/mysql-container/docker-entrypoint-initdb.d

    local DNS_DEFAULT_NAME=$(dns_default)
    if [ -z "$DNS_DEFAULT_NAME" ]; then
        echo "Default DNS is not found. Please create it first."
        exit 1
    fi

    # Start lamp-php first since nginx references lamp-php.

    container run -d --name $PHP_CONTAINER_NAME -v $DOCROOT:/var/www/html --network default $PHP_BUILDED_IMAGE
    if [ $? -ne 0 ]; then
        echo "Failed to run PHP container"
        exit 1
    fi

    container run -d --name $NGINX_CONTAINER_NAME -v $NGINX_CONFDIR:/etc/nginx/conf.d -v $DOCROOT:/var/www/html --network default -p 8080:80 $NGINX_IMAGE
    if [ $? -ne 0 ]; then
        echo "Failed to run Nginx container"
        exit 1
    fi

    container run -d --name $MYSQL_CONTAINER_NAME -v $MYSQL_INITDB:/docker-entrypoint-initdb.d -v $MYSQL_VOLUME:/var/lib/mysql --network default -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD $MYSQL_IMAGE
    if [ $? -ne 0 ]; then
        echo "Failed to run MySQL container"
        exit 1
    fi
}

# Stop and remove containers
cleanup_container() {
    container_stop $NGINX_CONTAINER_NAME
    container_stop $PHP_CONTAINER_NAME
    container_stop $MYSQL_CONTAINER_NAME

    container_rm $NGINX_CONTAINER_NAME
    container_rm $PHP_CONTAINER_NAME
    container_rm $MYSQL_CONTAINER_NAME
}

start() {
    # Start lamp-php first since nginx references lamp-php.
    container_start $PHP_CONTAINER_NAME
    container_start $NGINX_CONTAINER_NAME
    container_start $MYSQL_CONTAINER_NAME
}

stop() {
    container_stop $NGINX_CONTAINER_NAME
    container_stop $PHP_CONTAINER_NAME
    container_stop $MYSQL_CONTAINER_NAME
}

case "$1" in
    create)
        create
        ;;
    cleanup)
        cleanup
        ;;
    cleanup_container)
        cleanup_container
        ;;
    build)
        build
        ;;
    run)
        run
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage: $0 {create|cleanup|cleanup_container|run|start|stop}"
        exit 1
        ;;
esac

