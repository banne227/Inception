#!/bin/bash
set -e  # Quitter immédiatement si une commande échoue

# MariaDB crée son socket Unix dans /run/mysqld.
# Sur une image minimale, ce dossier n'existe pas toujours au boot du conteneur.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

INIT_MARKER="/var/lib/mysql/.inception_db_initialized"

# ── IDEMPOTENCE : bootstrap SQL piloté par un marqueur explicite ──
if [ ! -f "${INIT_MARKER}" ]; then
    echo "[MariaDB] Bootstrap initial (base + users)..."

    # Initialiser le datadir uniquement s'il n'existe pas encore.
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    fi

    # Démarrer MariaDB temporairement en local (sans réseau)
    # --skip-networking empêche les connexions externes pendant l'init
    mysqld --user=mysql --skip-networking --skip-grant-tables --socket=/run/mysqld/mysqld.sock &
    MYSQLD_PID=$!

    # Attendre que MariaDB soit prêt à accepter des connexions
    echo "[MariaDB] Attente du démarrage..."
    until mysqladmin --socket=/run/mysqld/mysqld.sock ping --silent 2>/dev/null; do
        sleep 1
    done
    echo "[MariaDB] Prêt — création de la base et des utilisateurs"

    # Créer la base, les utilisateurs, configurer root
    # Les variables viennent de .env via docker-compose
    mariadb --socket=/run/mysqld/mysqld.sock -u root <<-SQL
        FLUSH PRIVILEGES;
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
SQL

    # Arrêter MariaDB temporaire proprement
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQLD_PID

    touch "${INIT_MARKER}"
    echo "[MariaDB] Bootstrap terminé"
fi

# ── LANCER MARIADB EN PREMIER PLAN — devient PID 1 via exec ──
echo "[MariaDB] Démarrage en production..."
exec "$@"   # lance : mysqld
