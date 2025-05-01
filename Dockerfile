FROM node:18.20.8-slim AS node

# renovate: datasource=github-releases depName=npm packageName=npm/cli
ENV NPM_VERSION=9.9.4
RUN npm install -g "npm@${NPM_VERSION}"

FROM etriasnl/php-fpm:8.3.20-26

RUN ln -srf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN install-php-extensions xdebug

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget jq bash-completion unzip \
    s3cmd yamllint shellcheck \
    clamdscan \
    ffmpeg \
    libpng-dev \
    libdbi-perl libdbd-mysql-perl \
    gdb && \
    rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/bin/node /usr/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/lib/node_modules
RUN ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm
RUN ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx

# renovate: datasource=github-releases depName=dotenv-linter packageName=dotenv-linter/dotenv-linter
ENV DOTENV_LINTER_VERSION=v3.3.0
RUN curl -sSfL "https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/${DOTENV_LINTER_VERSION}/install.sh" | sh -s -- -b /usr/bin

# renovate: datasource=github-releases depName=natscli packageName=nats-io/natscli
ENV NATSCLI_VERSION=v0.2.2
RUN curl -sSfL "https://binaries.nats.dev/nats-io/natscli/nats@${NATSCLI_VERSION}" | PREFIX=/usr/bin sh

COPY docker/php-dev.ini /usr/local/etc/php/conf.d/

COPY docker/dev.bashrc /usr/local/etc/
RUN echo '. /usr/local/etc/dev.bashrc' >> /etc/bash.bashrc

ENV COMPOSER_HOME=/app/var/composer

RUN composer completion bash > /etc/bash_completion.d/composer
RUN chmod go+w /etc/bash_completion.d

WORKDIR /usr/local/etc/tools

COPY ["composer.json", "composer.lock", "./"]
RUN --mount=type=cache,target=/app/var/composer/cache \
    composer install --prefer-dist --no-progress --optimize-autoloader
RUN ln -sfn psalm.phar vendor/bin/psalm
ENV PATH="${PATH}:/usr/local/etc/tools/vendor/bin"

WORKDIR /app

RUN git config --global --add safe.directory /app
RUN npm config --global set engine-strict=true
