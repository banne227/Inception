#!/bin/bash
set -e

CERT_DIR="/etc/ssl/private"
CERT_KEY="${CERT_DIR}/nginx.key"
CERT_CRT="/etc/ssl/certs/nginx.crt"

mkdir -p ${CERT_DIR}

# ── IDEMPOTENCE : générer le certificat une seule fois ──
if [ ! -f "${CERT_CRT}" ]; then
    echo "[Nginx] Génération du certificat TLS auto-signé..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ${CERT_KEY} \
        -out   ${CERT_CRT} \
        -subj  "/C=FR/ST=IDF/L=Paris/O=42/OU=student/CN=${DOMAIN_NAME}"
    chmod 600 ${CERT_KEY}
    chmod 644 ${CERT_CRT}
fi

exec "$@"   # lance : nginx -g 'daemon off;'
