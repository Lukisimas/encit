FROM php:8.4-apache-bookworm

ARG MOODLE_VERSION=5.2.2
ARG MOODLE_SERIES=502
ARG MOODLE_URL=https://download.moodle.org/download.php/direct/stable${MOODLE_SERIES}/moodle-${MOODLE_VERSION}.tgz

ENV TZ=America/Mexico_City

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    libicu-dev libldap2-dev libonig-dev libxml2-dev libzip-dev \
    default-libmysqlclient-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-configure ldap \
  && docker-php-ext-install -j"$(nproc)" \
       exif gd intl ldap mbstring mysqli opcache soap zip \
  && a2enmod rewrite headers expires remoteip \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fL "$MOODLE_URL" -o /tmp/moodle.tgz \
  && rm -rf /var/www/html/* \
  && tar -xzf /tmp/moodle.tgz -C /tmp \
  && cp -a /tmp/moodle/. /var/www/html/ \
  && rm -rf /tmp/moodle /tmp/moodle.tgz \
  && mkdir -p /var/www/moodledata \
  && chown -R www-data:www-data /var/www/html /var/www/moodledata

COPY image/php.ini /usr/local/etc/php/conf.d/99-encit-moodle.ini
COPY image/apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1
