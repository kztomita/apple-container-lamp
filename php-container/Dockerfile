FROM php:8.4-fpm

COPY php-container/php.ini /usr/local/etc/php/

RUN apt-get update && apt-get install -y \
	curl \
	iputils-ping \
	default-mysql-client \
    && docker-php-ext-install pdo_mysql

# For Xdebug
RUN pecl install xdebug \
  && docker-php-ext-enable xdebug
COPY php-container/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www

