*This project has been created as part of the 42 curriculum by banne.*

## Description

**Inception** is a System Administration project from the 42 curriculum. The goal is to build a small, reproducible infrastructure using **Docker** and **Docker Compose** on a **Virtual Machine**.

This repository provides a minimal WordPress stack composed of **three services**, each running in its own container and built from **custom Dockerfiles** (no ready-made images pulled from registries, except the Debian base image):

- **mariadb**: database backend (MariaDB only)
- **wordpress**: WordPress running on **PHP-FPM** (no nginx in this container)
- **nginx**: the only public entrypoint, exposing **port 443** and enforcing **TLSv1.2/TLSv1.3**

The services communicate through a dedicated Docker **bridge network** named `inception`.  
Persistent data is stored using **Docker named volumes**, mapped to directories under `/home/${USER}/data` on the host as required by the subject.

## Repository structure

```
.
├── Makefile
└── srcs
    ├── docker-compose.yml
    ├── .env                 # NOT committed (must remain secret)
    └── requirements
        ├── mariadb
        │   ├── Dockerfile
        │   └── tools/setup.sh
        ├── nginx
        │   ├── Dockerfile
        │   ├── conf/default
        │   └── tools/setup.sh
        └── wordpress
            ├── Dockerfile
            ├── conf/www.conf
            └── tools
                ├── setup.sh
                └── wp-config.php
```

## Instructions

### Prerequisites

- Linux Virtual Machine (mandatory per subject)
- Docker Engine + Docker Compose plugin available (`docker compose`)
- Your domain name configured to point to the VM IP:
  - `banne.42.fr` → `<your-vm-ip>`

For local testing, you can add an entry in `/etc/hosts` on the machine you use to access the website:
- `<your-vm-ip> banne.42.fr`

### Environment variables (.env)

The stack is configured via `srcs/.env` (loaded with `env_file: .env` in Compose).  
This file contains:
- `DOMAIN_NAME` (here: `banne.42.fr`)
- MariaDB configuration (`MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`)
- WordPress configuration (site title, admin user + regular user)

**Security rule (subject requirement):**
- No passwords must be stored in Dockerfiles.
- Secrets must not be committed to Git.
- Using Docker secrets is recommended for confidential values.

### Build and run

From the repository root:

- Create host data directories and start everything:
  - `make up`

- Stop and remove the containers/network (keeps volumes/data):
  - `make down`

- Rebuild images:
  - `make build`

- Restart (down + up):
  - `make restart`

- View logs:
  - `make logs`

- Check status:
  - `make ps`

### Access

- Website:
  - `https://banne.42.fr`

- WordPress admin panel:
  - `https://banne.42.fr/wp-admin`

## Data persistence (volumes)

Two named volumes are used:

- `db` → mounted to `/var/lib/mysql` in the `mariadb` container  
  Host path: `/home/${USER}/data/db`

- `wordpress` → mounted to `/var/www/html` in `wordpress` and `nginx` containers  
  Host path: `/home/${USER}/data/wordpress`

This ensures:
- data persists across `make down` / `make up`
- the site survives container recreation

## Technical choices & required comparisons

### Virtual Machines vs Docker

- **Virtual Machines** virtualize hardware and run a full OS kernel per VM. They provide strong isolation but are heavier to run and manage.
- **Docker containers** virtualize at OS level (process isolation). They start fast, are lightweight, and provide reproducible service environments.

This project runs Docker inside a VM to enforce a stable, controlled environment during evaluation.

### Docker Network vs Host Network

- **Docker bridge networks** isolate container networking, provide internal DNS (service names), and avoid exposing internal services to the host.
- **Host networking** removes isolation by sharing the host network stack.

This project uses a dedicated bridge network (`inception`) and forbids `network_mode: host`.

### Docker Volumes vs Bind Mounts

- **Named volumes** are managed by Docker and are ideal for stable persistence.
- **Bind mounts** map an arbitrary host path directly into the container and are often used in development, but are restricted in this subject for the mandatory persistent storages.

This project uses named volumes with `driver_opts` to store data under `/home/${USER}/data`, matching the subject requirement.

## Resources

- Docker documentation: images, containers, Dockerfile best practices, volumes, networks
- Docker Compose documentation: services, networks, volumes, env_file
- NGINX documentation: TLS configuration
- WordPress documentation
- MariaDB documentation

## How AI was used

AI assistance was used to:
- draft and refine documentation files (README, USER_DOC, DEV_DOC)
- produce compliance checklists aligned with the subject constraints
- improve wording for the required technical comparisons
