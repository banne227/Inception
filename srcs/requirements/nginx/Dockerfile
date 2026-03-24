FROM debian:bullseye

RUN apt-get update && apt-get install -y \
        nginx \
        openssl \
    && rm -rf /var/lib/apt/lists/*

COPY ./conf/default /etc/nginx/sites-available/default
COPY ./tools/setup.sh  /setup.sh
RUN chmod +x /setup.sh

EXPOSE 443

ENTRYPOINT ["/setup.sh"]
CMD ["nginx", "-g", "daemon off;"]
