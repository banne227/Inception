# USER_DOC — Inception (User Documentation)

This document explains how to use the Inception stack as an end user or administrator.

## 1) What services does the stack provide?

The stack provides a secure WordPress website over HTTPS:

- **NGINX** (public entrypoint)
  - Exposes **port 443 only**
  - Enforces **TLSv1.2 / TLSv1.3**
  - Serves the WordPress site and forwards PHP requests to PHP-FPM

- **WordPress + PHP-FPM**
  - Runs the WordPress application (no nginx inside this container)

- **MariaDB**
  - Stores WordPress data (users, posts, configuration)

All containers communicate over the internal Docker network named `inception`.

## 2) How to start and stop the project

Run commands from the repository root.

### Start (build + run)

```sh
make up
```

On the first start, initialization can take a little longer (database + WordPress setup).

### Stop (keep persistent data)

```sh
make down
```

This stops/removes containers but keeps volumes (data remains on disk).

### View status

```sh
make ps
```

### View logs

```sh
make logs
```

## 3) How to access the website and admin panel

### Website

Open in a browser:

- `https://banne.42.fr`

### WordPress admin panel

- `https://banne.42.fr/wp-admin`

Use the WordPress admin credentials configured in the environment.

> Important: the subject forbids admin usernames containing `admin`/`administrator`.  
> In this repository, the configured admin username is `WP_ADMIN_USER=banne`.

## 4) Where are credentials located and how to manage them?

### `.env` configuration file

Credentials and configuration are stored in:

- `srcs/.env`

This file includes:
- Domain: `DOMAIN_NAME=banne.42.fr`
- Database variables: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`
- WordPress variables: `WP_ADMIN_*`, `WP_USER_*`, etc.

**Security warning (mandatory):**
- Do not commit `.env` to git if it contains real passwords.
- Prefer storing sensitive values using secret files ignored by git or Docker secrets.

## 5) How to verify everything works

### A) Service health (containers running)

```sh
docker compose -f srcs/docker-compose.yml ps
```

Expected services:
- `mariadb` running
- `wordpress` running
- `nginx` running

### B) Website reachable over HTTPS

Open:

- `https://banne.42.fr`

You should land on the WordPress website.

### C) Persistence check

1. Create a post or update a setting in WordPress.
2. Stop the stack:
   - `make down`
3. Start again:
   - `make up`
4. Verify your changes are still present.

### D) If something is broken (quick troubleshooting)

- Read logs:
  - `docker compose -f srcs/docker-compose.yml logs -f mariadb`
  - `docker compose -f srcs/docker-compose.yml logs -f wordpress`
  - `docker compose -f srcs/docker-compose.yml logs -f nginx`

- Enter a container:
  - `docker compose -f srcs/docker-compose.yml exec wordpress sh`
  - `docker compose -f srcs/docker-compose.yml exec mariadb sh`
