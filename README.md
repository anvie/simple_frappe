# Simple Frappe Docker

A streamlined Docker setup for Frappe based app development, simplifying the official Frappe Docker configuration for faster local development.

## Quick Start

Start the Frappe environment with Docker Compose:

```bash
docker compose up -d
```

**Access the application:**

- Web Interface: http://localhost:8080
- Default User: `Administrator`
- Default Password: `admin`

## Installing Frappe Apps

You can install Frappe applications using two methods:

### Method 1: Pre-installation (Recommended)

Clone your apps into `frappe-bench/apps` before starting the containers. They will be automatically detected and installed during the first run.

**Example - Installing ERPNext v15:**

```bash
cd frappe-bench/apps
git clone -b version-15 https://github.com/frappe/erpnext.git
```

### Method 2: Post-installation

Install apps after the containers are running using the `bench` command inside the container.

**Example:**

```bash
docker compose exec frappe bash

bench get-app erpnext --branch version-15
bench --site frontend install-app erpnext
```

## Development Environment

### Volume Mounts

The following directories are mounted as volumes for seamless development:

- `frappe-bench/apps` - Your Frappe applications
- `frappe-bench/sites` - Site configurations and data

Changes made to files in these directories on your host machine are immediately reflected in the container.

### Container Architecture

This setup includes:

- **Frappe** container with Frappe v15 framework
- **MariaDB 10.6** for database
- **Redis** instances for caching and queue management
- **Supervisor** for process management

### Useful Commands

```bash
# View container logs
docker compose logs -f frappe

# Access container shell
docker compose exec frappe bash

# Stop containers
docker compose down

# Stop and remove volumes (careful - deletes data)
docker compose down -v
```

### Ports

- `8080` - Web interface (Nginx)
- `8000` - Frappe backend server

For detailed configuration, see `docker-compose.yml`.

---

[] Robin Syihab
