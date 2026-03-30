# DEV_DOC — Inception (Developer Documentation)

This document describes how to set up, build, run, and debug the Inception project as a developer.

## 1) Stack overview

Compose file: `srcs/docker-compose.yml`

Services:
- `mariadb` (database)
- `wordpress` (PHP-FPM + WordPress)
- `nginx` (TLS entrypoint, only port 443 exposed)

Network:
- `inception` (bridge)

Volumes (named volumes mapped to host paths):
- `db` → `/var/lib/mysql` → `/home/${USER}/data/db`
- `wordpress` → `/var/www/html` → `/home/${USER}/data/wordpress`

## 2) Setup from scratch

### Prerequisites

- Linux VM
- Docker Engine installed
- Docker Compose plugin (`docker compose version`)

### Domain configuration

The environment uses:

- `DOMAIN_NAME=banne.42.fr`

Ensure `banne.42.fr` points to your VM IP address.

For local testing, you can use `/etc/hosts` on the client machine:
- `<vm-ip> banne.42.fr`

### Required configuration files

- `srcs/docker-compose.yml`
- `srcs/.env` (must exist locally)
- Dockerfiles:
  - `srcs/requirements/mariadb/Dockerfile`
  - `srcs/requirements/wordpress/Dockerfile`
  - `srcs/requirements/nginx/Dockerfile`

Initialization scripts:
- `srcs/requirements/mariadb/tools/setup.sh`
- `srcs/requirements/wordpress/tools/setup.sh`
- `srcs/requirements/nginx/tools/setup.sh`

## 3) Build & launch workflow

### Makefile commands (preferred)

From repository root:

- Create `/home/${USER}/data/...` directories:
  - `make setup`

- Build images:
  - `make build`

- Build + start:
  - `make up`

- Stop/remove containers + network (keep volumes/data):
  - `make down`

- Restart:
  - `make restart`

### Direct Docker Compose commands

```sh
docker compose -f srcs/docker-compose.yml up -d --build
docker compose -f srcs/docker-compose.yml down
```

## 4) Managing containers & debugging

### Logs

All services:
```sh
docker compose -f srcs/docker-compose.yml logs -f
```

Single service:
```sh
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx
```

### Shell access

```sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec nginx sh
```

### Network / DNS checks

Inside `wordpress`, MariaDB must be reachable by service name:
- host: `mariadb`
- port: `3306`

You can validate connectivity using a MySQL client if installed in the container, or by checking WordPress startup logs.

## 5) Persistent data and where it is stored

The subject requires that persistent data is stored under:

- `/home/<login>/data`

This project uses:
- `/home/${USER}/data/db` for MariaDB
- `/home/${USER}/data/wordpress` for WordPress files

Because the containers mount named volumes to these host paths, data persists across container recreation.

### Persistence test procedure

1. Start:
   - `make up`
2. Create a WordPress post.
3. Stop:
   - `make down`
4. Start again:
   - `make up`
5. Confirm the post still exists.

## 6) Notes about the `.env` file and security

Current `.env` variables include (example):
- `DOMAIN_NAME=banne.42.fr`
- `MYSQL_ROOT_PASSWORD=...`
- `MYSQL_DATABASE=wordpress`
- `MYSQL_USER=wpdbuser`
- `MYSQL_PASSWORD=...`
- `WP_ADMIN_USER=banne`
- `WP_ADMIN_PASS=...`
- `WP_USER=...`

**Mandatory rules:**
- No passwords in Dockerfiles
- Avoid committing `.env` if it contains real credentials
- Prefer secret files ignored by git or Docker secrets for confidential data

## 7) Common evaluation failure points (checklist)

- Exposing any port other than 443 (mandatory part)
- Not enforcing TLSv1.2/TLSv1.3 in NGINX
- Using `latest` tag
- Pulling ready-made service images from registries (except Debian/Alpine base)
- Using forbidden networking (`network_mode: host`, `links`)
- Using infinite loops (`tail -f`, `sleep infinity`, `while true`) to keep containers alive
- Using bind mounts instead of the required named volumes for DB and WP persistence
- Not storing persistent data under `/home/${USER}/data`
- Credentials committed into the Git repository
- WordPress admin username contains `admin` / `administrator`
