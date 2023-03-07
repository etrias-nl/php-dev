FROM node:16.19.1-slim as node
FROM composer:2.5.4 as composer
FROM stephenc/envsub:0.1.3 as envsub
FROM etriasnl/percona-toolkit:3.3.1 as pt_toolkit
FROM etriasnl/php-extensions:7.4-bullseye-apcu-5.1.21 as module_apcu
FROM etriasnl/php-extensions:7.4-bullseye-bcmath-0 as module_bcmath
FROM etriasnl/php-extensions:7.4-bullseye-calendar-0 as module_calendar
FROM etriasnl/php-extensions:7.4-bullseye-exif-0 as module_exif
FROM etriasnl/php-extensions:7.4-bullseye-gd-5 as module_gd
FROM etriasnl/php-extensions:7.4-bullseye-gearman-2.1.0 as module_gearman
FROM etriasnl/php-extensions:7.4-bullseye-gmagick-2.0.6rc1-1.3.38-17 as module_gmagick
FROM etriasnl/php-extensions:7.4-bullseye-igbinary-3.2.6 as module_igbinary
FROM etriasnl/php-extensions:7.4-bullseye-imap-0 as module_imap
FROM etriasnl/php-extensions:7.4-bullseye-intl-0 as module_intl
FROM etriasnl/php-extensions:7.4-bullseye-opcache-0 as module_opcache
FROM etriasnl/php-extensions:7.4-bullseye-pcntl-0 as module_pcntl
FROM etriasnl/php-extensions:7.4-bullseye-pdo_mysql-0 as module_pdo_mysql
FROM etriasnl/php-extensions:7.4-bullseye-redis-5.3.4 as module_redis
FROM etriasnl/php-extensions:7.4-bullseye-soap-0 as module_soap
FROM etriasnl/php-extensions:7.4-bullseye-sockets-0 as module_sockets
FROM etriasnl/php-extensions:7.4-bullseye-xdebug-3.1.2 as module_xdebug
FROM etriasnl/php-extensions:7.4-bullseye-memprof-3.0.2 as module_memprof
FROM etriasnl/php-extensions:7.4-bullseye-meminfo-1.1.1 as module_meminfo
FROM etriasnl/php-extensions:7.4-bullseye-zip-1 as module_zip

FROM php:7.4.33-fpm AS php

RUN useradd -ms /bin/bash --uid 1500 symfony

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=envsub /bin/envsub /usr/bin/
COPY --from=pt_toolkit /usr/local/bin/pt-online-schema-change /usr/bin/
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
COPY --from=module_pcntl /extension/ /extensions/pcntl
COPY --from=module_pdo_mysql /extension/ /extensions/pdo_mysql
COPY --from=module_redis /extension/ /extensions/redis
COPY --from=module_soap /extension/ /extensions/soap
COPY --from=module_sockets /extension/ /extensions/sockets
COPY --from=module_xdebug /extension/ /extensions/xdebug
COPY --from=module_memprof /extension/ /extensions/memprof
COPY --from=module_meminfo /extension/ /extensions/meminfo
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
    && /extensions/pcntl/install.sh \
    && /extensions/pdo_mysql/install.sh \
    && /extensions/redis/install.sh \
    && /extensions/soap/install.sh \
    && /extensions/sockets/install.sh \
    && /extensions/xdebug/install.sh \
    && /extensions/memprof/install.sh \
    && /extensions/meminfo/install.sh \
    && /extensions/zip/install.sh \
    && rm -rf /extensions

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    procps \
    libpng-dev \
    dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget bash-completion \
    s3cmd \
    libdbi-perl libdbd-mysql-perl \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /etc/profile.d/bash_completion.sh" >> /root/.bashrc \
    && echo "alias ll='ls -alF --group-directories-first --color=auto'" >> /root/.bashrc \
    && echo "alias xphp='XDEBUG_TRIGGER=PHPSTORM php'" >> /root/.bashrc \
    && echo "alias memprofphp='MEMPROF_PROFILE=1 php'" >> /root/.bashrc

# hadolint ignore=DL4006
RUN composer completion bash | tee /etc/bash_completion.d/composer

COPY php-ini/* /usr/local/etc/php/conf.d/
COPY tools/php-7.4 /usr/local/etc/tools

RUN composer install --working-dir=/usr/local/etc/tools
ENV PATH="${PATH}:/usr/local/etc/tools/vendor/bin"

RUN mkdir -m777 /var/okteto

WORKDIR /app

FROM php as php_node

COPY --from=node /usr/local/bin/node /usr/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/lib/node_modules
COPY --from=node /opt/yarn* /opt/yarn

RUN ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm && \
    ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx && \
    ln -s /opt/yarn/bin/yarn.js /usr/bin/yarn && \
    yarn config set cache-folder /yarn/cache
