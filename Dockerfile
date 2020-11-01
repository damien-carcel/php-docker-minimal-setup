######################################
# Base image for common dependencies #
# between development and production #
######################################

FROM debian:buster-slim as base

ENV DEBIAN_FRONTEND=noninteractive\
    PHP_CONF_DATE_TIMEZONE=UTC \
    PHP_CONF_DISPLAY_ERRORS=0 \
    PHP_CONF_DISPLAY_STARTUP_ERRORS=0 \
    PHP_CONF_MAX_EXECUTION_TIME=60 \
    PHP_CONF_MAX_INPUT_VARS=1000 \
    PHP_CONF_MAX_POST_SIZE=40M \
    PHP_CONF_MEMORY_LIMIT=512M \
    PHP_CONF_ERROR_REPORTING=22527 \
    PHP_CONF_UPLOAD_LIMIT=40M \
    PHP_CONF_OPCACHE_VALIDATE_TIMESTAMP=0 \
    PHP_CONF_ZEND_ASSERTIONS=-1 \
    XDEBUG_ENABLED=0

RUN echo 'APT::Install-Recommends "0" ; APT::Install-Suggests "0" ;' > /etc/apt/apt.conf.d/01-no-recommended && \
    echo 'path-exclude=/usr/share/doc/*' > /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/groff/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/linda/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/lintian/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/locale/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    echo 'path-exclude=/usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/path_exclusions && \
    apt-get update && \
    apt-get --yes install apt-transport-https ca-certificates gpg gpg-agent wget && \
    echo 'deb https://packages.sury.org/php/ buster main' > /etc/apt/sources.list.d/sury.list && \
    wget -O sury.gpg https://packages.sury.org/php/apt.gpg && apt-key add sury.gpg && rm sury.gpg && \
    apt-get update && \
    apt-get --yes install \
        php7.4-apcu \
        php7.4-cli \
        php7.4-curl \
        php7.4-dom \
        php7.4-fpm \
        php7.4-intl \
        php7.4-json \
        php7.4-mbstring \
        php7.4-mysql \
        php7.4-opcache \
        php7.4-pdo \
        php7.4-zip && \
    apt-get clean && \
    apt-get --yes autoremove --purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    ln -s /usr/sbin/php-fpm7.4 /usr/local/sbin/php-fpm && \
    mkdir /run/php/

COPY docker/php/app.ini /etc/php/7.4/cli/conf.d/99-app.ini
COPY docker/php/app.ini /etc/php/7.4/fpm/conf.d/99-app.ini
COPY docker/php/fpm.conf /etc/php/7.4/fpm/pool.d/zzz.conf

##################################
# PHP image used for development #
##################################

FROM base as dev

ENV XDEBUG_ENABLED=0

# Install Git and XDEBUG
RUN apt-get update && \
    apt-get --yes install \
        git \
        php7.4-xdebug \
        unzip && \
    apt-get clean && \
    apt-get --yes autoremove --purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    phpdismod xdebug && \
    mkdir /etc/php/7.4/enable-xdebug && \
    ln -s /etc/php/7.4/mods-available/xdebug.ini /etc/php/7.4/enable-xdebug/xdebug.ini

# Configure XDEBUG and make XDEBUG activable at container start
COPY docker/php/xdebug.ini /etc/php/7.4/cli/conf.d/99-xdebug.ini
COPY docker/php/xdebug.ini /etc/php/7.4/fpm/conf.d/99-xdebug.ini
COPY docker/php/docker-php-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-entrypoint

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

ENTRYPOINT ["/usr/local/bin/docker-php-entrypoint"]