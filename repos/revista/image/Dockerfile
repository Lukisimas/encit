# syntax=docker/dockerfile:1.7

# Imagen reproducible de OJS. No se instala OJS manualmente en cada entorno:
# Jenkins crea esta imagen una vez y la publica en el Registry de Gitea.
FROM php:8.3-apache-bookworm

ARG OJS_VERSION=3.5.0-5
ARG OJS_URL=https://pkp.sfu.ca/ojs/download/ojs-${OJS_VERSION}.tar.gz

LABEL org.opencontainers.image.title="ENCiT Open Journal Systems"
LABEL org.opencontainers.image.description="OJS empaquetado para los entornos ENCiT"
LABEL org.opencontainers.image.version="${OJS_VERSION}"
LABEL org.opencontainers.image.source="https://pkp.sfu.ca/software/ojs/"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Mexico_City

# Bibliotecas necesarias para las extensiones PHP utilizadas por OJS.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip tar git \
      libcurl4-openssl-dev \
      libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
      libicu-dev libonig-dev libxml2-dev libzip-dev \
      poppler-utils \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
      bcmath curl ftp gd intl mbstring mysqli opcache soap zip \
    && a2enmod rewrite headers expires remoteip \
    && rm -rf /var/lib/apt/lists/*

# Descarga el paquete de RELEASE, no el código fuente del repositorio. PKP
# recomienda los paquetes de release para despliegues de producción.
RUN curl -fL "${OJS_URL}" -o /tmp/ojs.tar.gz \
    && tar -xzf /tmp/ojs.tar.gz -C /tmp \
    && rm -rf /var/www/html/* \
    && cp -a "/tmp/ojs-${OJS_VERSION}/." /var/www/html/ \
    && rm -rf /tmp/ojs.tar.gz "/tmp/ojs-${OJS_VERSION}" \
    && mkdir -p /var/www/ojs-files /var/www/html/cache /var/www/html/public \
    && chown -R www-data:www-data /var/www/html /var/www/ojs-files

COPY image/php.ini /usr/local/etc/php/conf.d/99-encit-ojs.ini
COPY image/apache-ojs.conf /etc/apache2/conf-available/encit-ojs.conf
RUN a2enconf encit-ojs

# Verificación temprana de extensiones críticas. Si una futura imagen PHP
# cambia y falta una extensión, el build falla antes de llegar a producción.
RUN php -r 'foreach (["bcmath","curl","gd","intl","mysqli","zip"] as $e) { if (!extension_loaded($e)) { fwrite(STDERR, "Missing extension: $e\n"); exit(1); } }'

WORKDIR /var/www/html
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
  CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1
