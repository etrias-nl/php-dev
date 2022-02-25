FROM composer/composer:2.2.6 as composer
FROM etriasnl/php-extensions:7.4-bullseye-apcu-5.1.21 as module_apcu
FROM etriasnl/php-extensions:7.4-bullseye-bcmath-0 as module_bcmath
FROM etriasnl/php-extensions:7.4-bullseye-exif-0 as module_exif
FROM etriasnl/php-extensions:7.4-bullseye-gd-0 as module_gd
FROM etriasnl/php-extensions:7.4-bullseye-gearman-2.1.0 as module_gearman
FROM etriasnl/php-extensions:7.4-bullseye-gmagick-2.0.6rc1 as module_gmagick
FROM etriasnl/php-extensions:7.4-bullseye-igbinary-3.2.6 as module_igbinary
FROM etriasnl/php-extensions:7.4-bullseye-imap-0 as module_imap
FROM etriasnl/php-extensions:7.4-bullseye-intl-0 as module_intl
FROM etriasnl/php-extensions:7.4-bullseye-opcache-0 as module_opcache
FROM etriasnl/php-extensions:7.4-bullseye-pdo_mysql-0 as module_pdo_mysql
FROM etriasnl/php-extensions:7.4-bullseye-redis-5.3.4 as module_redis
FROM etriasnl/php-extensions:7.4-bullseye-soap-0 as module_soap
FROM etriasnl/php-extensions:7.4-bullseye-sockets-0 as module_sockets
FROM etriasnl/php-extensions:7.4-bullseye-xdebug-3.1.2 as module_xdebug
FROM etriasnl/php-extensions:7.4-bullseye-zip-0 as module_zip

FROM php:7.4.28-fpm

ARG APP_ENV
ARG APP_DEBUG

ENV APP_ENV $APP_ENV
ENV APP_DEBUG $APP_DEBUG

COPY --from=module_apcu /extension/ /extensions/apcu
COPY --from=module_bcmath /extension/ /extensions/bcmath
COPY --from=module_exif /extension/ /extensions/exif
COPY --from=module_gd /extension/ /extensions/gd
COPY --from=module_gearman /extension/ /extensions/gearman
COPY --from=module_gmagick /extension/ /extensions/gmagick
COPY --from=module_igbinary /extension/ /extensions/igbinary
COPY --from=module_imap /extension/ /extensions/imap
COPY --from=module_intl /extension/ /extensions/intl
COPY --from=module_opcache /extension/ /extensions/opcache
COPY --from=module_pdo_mysql /extension/ /extensions/pdo_mysql
COPY --from=module_redis /extension/ /extensions/redis
COPY --from=module_soap /extension/ /extensions/soap
COPY --from=module_sockets /extension/ /extensions/sockets
COPY --from=module_xdebug /extension/ /extensions/xdebug
COPY --from=module_zip /extension/ /extensions/zip

RUN /extensions/apcu/install.sh && \
  /extensions/bcmath/install.sh && \
  /extensions/exif/install.sh && \
  /extensions/gd/install.sh && \
  /extensions/gearman/install.sh && \
  /extensions/gmagick/install.sh && \
  /extensions/igbinary/install.sh && \
  /extensions/imap/install.sh && \
  /extensions/intl/install.sh && \
  /extensions/opcache/install.sh && \
  /extensions/pdo_mysql/install.sh && \
  /extensions/redis/install.sh && \
  /extensions/soap/install.sh && \
  /extensions/sockets/install.sh && \
  /extensions/xdebug/install.sh && \
  /extensions/zip/install.sh


COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY php_ini/* /usr/local/etc/php/conf.d

RUN mkdir /app && cd /app
WORKDIR /app