FROM etriasnl/php-fpm:8.3.30-40

RUN ln -srf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget jq bash-completion unzip \
    s3cmd yamllint shellcheck \
    clamdscan \
    ffmpeg \
    libpng-dev \
    libdbi-perl libdbd-mysql-perl \
    gdb && \
    rm -rf /var/lib/apt/lists/*

# renovate: datasource=github-releases depName=xdebug packageName=xdebug/xdebug
ENV EXT_XDEBUG_VERSION=3.5.0
RUN install-php-extensions xdebug-${EXT_XDEBUG_VERSION}

# renovate: datasource=github-releases depName=dotenv-linter packageName=dotenv-linter/dotenv-linter
ENV DOTENV_LINTER_VERSION=v4.0.0
RUN curl -sSfL "https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/${DOTENV_LINTER_VERSION}/install.sh" | sh -s -- -b /usr/bin

# renovate: datasource=github-releases depName=natscli packageName=nats-io/natscli
ENV NATSCLI_VERSION=v0.3.0
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') && \
    curl -sSfL "https://github.com/nats-io/natscli/releases/download/${NATSCLI_VERSION}/nats-${NATSCLI_VERSION#v}-linux-${ARCH}.zip" -o /tmp/natscli.zip && \
    unzip -q /tmp/natscli.zip "nats-${NATSCLI_VERSION#v}-linux-${ARCH}/nats" -d /tmp && \
    mv /tmp/nats-${NATSCLI_VERSION#v}-linux-${ARCH}/nats /usr/bin/nats && \
    chmod +x /usr/bin/nats && \
    rm -rf /tmp/natscli.zip /tmp/nats-${NATSCLI_VERSION#v}-linux-${ARCH}

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
