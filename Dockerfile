FROM node:16.20.2-slim as node

FROM etriasnl/php-fpm:8.1.27-5

RUN chmod 0666 /var/log/newrelic/newrelic-daemon.log # @todo cleanup

RUN ln -srf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN install-php-extensions xdebug

RUN apt-get update && apt-get install -y --no-install-recommends \
    dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget jq bash-completion unzip \
    s3cmd yamllint shellcheck \
    clamdscan \
    ffmpeg \
    libpng-dev \
    libdbi-perl libdbd-mysql-perl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSfL 'https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh' | sh -s -- -b /usr/bin

COPY --from=node /usr/local/bin/node /usr/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/lib/node_modules
COPY --from=node /opt/yarn* /opt/yarn

RUN ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm && \
    ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx && \
    ln -s /opt/yarn/bin/yarn.js /usr/bin/yarn && \
    chmod 0777 /usr/local/share/.yarnrc && ln -s /usr/local/share/.yarnrc /.yarnrc

COPY docker/php-dev.ini /usr/local/etc/php/conf.d/

COPY docker/dev.bashrc /usr/local/etc/
RUN echo '. /usr/local/etc/dev.bashrc' >> /etc/bash.bashrc

RUN nats --completion-script-bash > /etc/bash_completion.d/nats
RUN composer completion bash > /etc/bash_completion.d/composer

WORKDIR /usr/local/etc/tools

COPY composer.* .
RUN --mount=type=cache,target=/tmp/build/composer \
    composer install --prefer-dist --no-progress --optimize-autoloader
ENV PATH="${PATH}:/usr/local/etc/tools/vendor/bin"
RUN ln -sfn psalm.phar vendor/bin/psalm
RUN rm -rf /root/.composer

WORKDIR /app

ENV PATH="${PATH}:/usr/local/etc/tools/vendor/bin"
ENV COMPOSER_HOME=/app/var/composer
RUN yarn config set cache-folder /app/var/yarn-cache
