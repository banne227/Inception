FROM debian:bullseye

# Installer PHP-FPM et les extensions nécessaires à WordPress
RUN apt-get update && apt-get install -y \
        php7.4-fpm \
        php7.4-mysql \
        php7.4-curl \
        php7.4-gd \
        php7.4-mbstring \
        php7.4-xml \
        php7.4-zip \
    mariadb-client \
        wget curl \
    && rm -rf /var/lib/apt/lists/*

# Installer WP-CLI — outil CLI officiel de WordPress
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Config PHP-FPM : écouter sur port 9000
COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY ./tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

# Créer le répertoire web avec bonnes permissions
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

EXPOSE 9000
ENTRYPOINT ["/setup.sh"]
# -F = foreground (obligatoire pour PID 1)
CMD ["php-fpm7.4", "-F"]
