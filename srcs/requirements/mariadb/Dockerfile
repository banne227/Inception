FROM debian:bullseye

# Installer MariaDB — nettoyer le cache apt dans le même RUN
# Bonne pratique : une seule couche pour installation + nettoyage
RUN apt-get update && apt-get install -y \
        mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY ./tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 3306

# setup.sh s'occupe de l'init puis lance mysqld via exec
ENTRYPOINT ["/setup.sh"]
CMD ["mysqld", "--bind-address=0.0.0.0"]