FROM node:16.16.0-slim as node
FROM composer:2.3.10 as composer
FROM stephenc/envsub:0.1.3 as envsub
FROM etriasnl/php-extensions:7.4-bullseye-apcu-5.1.21 as module_apcu
FROM etriasnl/php-extensions:7.4-bullseye-bcmath-0 as module_bcmath
FROM etriasnl/php-extensions:7.4-bullseye-calendar-0 as module_calendar
FROM etriasnl/php-extensions:7.4-bullseye-exif-0 as module_exif
FROM etriasnl/php-extensions:7.4-bullseye-gd-2 as module_gd
FROM etriasnl/php-extensions:7.4-bullseye-gearman-2.1.0 as module_gearman
FROM etriasnl/php-extensions:7.4-bullseye-gmagick-2.0.6rc1-1.3.38 as module_gmagick
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

FROM php:7.4.30-fpm AS php

RUN useradd -ms /bin/bash --uid 1500 symfony

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=envsub /bin/envsub /usr/bin/
COPY --from=module_apcu /extension/ /extensions/apcu
COPY --from=module_bcmath /extension/ /extensions/bcmath
COPY --from=module_calendar /extension/ /extensions/calendar
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

RUN /extensions/apcu/install.sh \
    && /extensions/bcmath/install.sh \
    && /extensions/calendar/install.sh \
    && /extensions/exif/install.sh \
    && /extensions/gd/install.sh \
    && /extensions/gearman/install.sh \
    && /extensions/gmagick/install.sh \
    && /extensions/igbinary/install.sh \
    && /extensions/imap/install.sh \
    && /extensions/intl/install.sh \
    && /extensions/opcache/install.sh \
    && /extensions/pdo_mysql/install.sh \
    && /extensions/redis/install.sh \
    && /extensions/soap/install.sh \
    && /extensions/sockets/install.sh \
    && /extensions/xdebug/install.sh \
    && /extensions/zip/install.sh

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    libpng-dev \
    dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget bash-completion \
    s3cmd \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /usr/bin/composer-normalize https://github.com/ergebnis/composer-normalize/releases/latest/download/composer-normalize.phar && chmod +x /usr/bin/composer-normalize
RUN wget -qO /usr/bin/psalm https://github.com/vimeo/psalm/releases/latest/download/psalm.phar && chmod +x /usr/bin/psalm
RUN wget -qO /usr/bin/php-cs-fixer https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/latest/download/php-cs-fixer.phar && chmod +x /usr/bin/php-cs-fixer
RUN wget -qO /usr/bin/phpunit.phar https://phar.phpunit.de/phpunit-9.phar && chmod +x /usr/bin/phpunit.phar \
    && phar extract -f /usr/bin/phpunit.phar /opt/phpunit-src \
    && mv /usr/bin/phpunit.phar /usr/bin/phpunit

RUN echo "source /etc/profile.d/bash_completion.sh" >> /root/.bashrc \
    && echo "alias ll='ls -alF --group-directories-first --color=auto'" >> /root/.bashrc \
    && echo "alias xphp='XDEBUG_TRIGGER=PHPSTORM php'" >> /root/.bashrc

COPY php-ini/* /usr/local/etc/php/conf.d/

RUN mkdir -m777 /var/okteto

WORKDIR /app

FROM php as php_node

COPY --from=node /usr/local/bin/node /usr/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/lib/node_modules
COPY --from=node /opt/yarn* /opt/yarn

RUN ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm
RUN ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx
RUN ln -s /opt/yarn/bin/yarn.js /usr/bin/yarn
RUN yarn config set cache-folder /yarn/cache
