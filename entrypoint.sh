#!/usr/bin/env bash

set -ue

source /etc/profile.d/bash_completion.sh
php-fpm -F --pid /usr/local/php/php/fpm/php-fpm.pid -y /usr/local/etc/php-fpm.conf
