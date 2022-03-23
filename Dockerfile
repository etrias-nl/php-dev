FROM artifacts.eko/docker.io/composer/composer:2.2.9 as composer
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-apcu-5.1.21 as module_apcu
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-bcmath-0 as module_bcmath
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-exif-0 as module_exif
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-gd-0 as module_gd
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-gearman-2.1.0 as module_gearman
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-gmagick-2.0.6rc1 as module_gmagick
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-igbinary-3.2.6 as module_igbinary
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-imap-0 as module_imap
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-intl-0 as module_intl
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-opcache-0 as module_opcache
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-pdo_mysql-0 as module_pdo_mysql
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-redis-5.3.4 as module_redis
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-soap-0 as module_soap
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-sockets-0 as module_sockets
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-xdebug-3.1.2 as module_xdebug
FROM artifacts.eko/docker.io/etriasnl/php-extensions:7.4-bullseye-zip-0 as module_zip

FROM artifacts.eko/docker.io/library/php:7.4.28-fpm

COPY --from=composer /usr/bin/composer /usr/bin/composer
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

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    git \
    vim nano \
    curl wget \
    dnsutils iputils-ping lsof net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/bin/composer-normalize https://github.com/ergebnis/composer-normalize/releases/latest/download/composer-normalize.phar && chmod +x /usr/bin/composer-normalize
RUN wget -O /usr/bin/psalm https://github.com/vimeo/psalm/releases/latest/download/psalm.phar && chmod +x /usr/bin/psalm
RUN wget -O /usr/bin/php-cs-fixer https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/latest/download/php-cs-fixer.phar && chmod +x /usr/bin/php-cs-fixer
RUN wget -O /usr/bin/phpunit.phar https://phar.phpunit.de/phpunit-9.phar && chmod +x /usr/bin/phpunit.phar \
    && phar extract -f /usr/bin/phpunit.phar /opt/phpunit-src \
    && mv /usr/bin/phpunit.phar /usr/bin/phpunit

COPY php_ini/* /usr/local/etc/php/conf.d

WORKDIR /app
