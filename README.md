# Simple Frappe Docker

Simplified version of the official Frappe Docker setup.

## How to use

Run docker compose to start:

```bash
docker compose up -d
```

## Install Frappe Apps

there are two ways to install apps:

### 1. Predefined Apps

When run with `docker compose up -d` the first time, it will install the apps
in `frappe-bench/apps`, so you can simply clone your apps there before starting the containers.

Example, for ERPNext version 15:

```bash
cd frappe-bench/apps
git clone -b version-15 https://github.com/frappe/erpnext.git
```

### 2. Install Apps Manually

After starting the containers, you can enter the `frappe` container and use the `bench` command to install apps.

Example:

```bash
docker compose exec frappe bash

bench get-app erpnext --branch version-15
bench --site frontend install-app erpnext
```

## Development

The `apps` dir and `sites` dir are mounted as volumes in current directory, so
you can easily develop your own apps on your host machine and test them in the container.

See `docker-compose.yml` for more details.

[] Robin Syihab
