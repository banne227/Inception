#!/bin/bash
set -e

WP_PATH="/var/www/html"

# URL canonique WordPress (inclut le port host si non-standard)
WP_SCHEME="${WP_SCHEME:-https}"
WP_PORT="${WP_PORT:-8443}"
if [ -n "${WP_PORT}" ] && [ "${WP_PORT}" != "443" ]; then
    WP_URL="${WP_SCHEME}://${DOMAIN_NAME}:${WP_PORT}"
else
    WP_URL="${WP_SCHEME}://${DOMAIN_NAME}"
fi

# ── ATTENTE MARIADB — ne pas se connecter avant que la DB soit prête ──
echo "[WordPress] Attente de MariaDB..."
until mariadb -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} \
    -e 'SELECT 1;' ${MYSQL_DATABASE} > /dev/null 2>&1; do
    echo "[WordPress] MariaDB pas encore prêt, attente 3s..."
    sleep 3
done
echo "[WordPress] MariaDB prêt !"

# ── IDEMPOTENCE : installer WP seulement si pas encore fait ──
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
    echo "[WordPress] Première installation..."

    # Télécharger WordPress core
    wp core download --allow-root --path=${WP_PATH} --locale=fr_FR

    # Créer wp-config.php — 'mariadb' = DNS interne Docker
    wp config create --allow-root --path=${WP_PATH} \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --dbprefix=wp_

    # Installer WordPress (crée toutes les tables dans la DB)
    wp core install --allow-root --path=${WP_PATH} \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email

    # Créer le second utilisateur (non-admin)
    # Le sujet impose 2 users : 1 admin + 1 user standard
    wp user create --allow-root --path=${WP_PATH} \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASS}" \
        --role=author

    echo "[WordPress] Installation terminée !"
fi

# Mettre a jour home/siteurl a chaque demarrage pour suivre le port expose.
if wp core is-installed --allow-root --path=${WP_PATH} > /dev/null 2>&1; then
    wp option update home "${WP_URL}" --allow-root --path=${WP_PATH} > /dev/null
    wp option update siteurl "${WP_URL}" --allow-root --path=${WP_PATH} > /dev/null
fi

# ── PERMISSIONS — www-data doit posséder tous les fichiers ──
chown -R www-data:www-data ${WP_PATH}
find ${WP_PATH} -type d -exec chmod 755 {} \;
find ${WP_PATH} -type f -exec chmod 644 {} \;
# uploads doit être inscriptible
chmod -R 775 ${WP_PATH}/wp-content/uploads 2>/dev/null || true

# S'assurer que le dossier runtime PHP existe pour le PID de php-fpm.
mkdir -p /run/php
chown -R www-data:www-data /run/php

# ── LANCER PHP-FPM EN PREMIER PLAN — devient PID 1 ──
exec "$@"   # lance : php-fpm7.4 -F
