#!/usr/bin/env bash
# Script ini hanya boleh dijalankan menggunakan user fappe, bukan root.

set -e

ROOT_USERNAME=root
ROOT_PASSWORD=admin
REDIS_CACHE=redis-cache:6379
REDIS_QUEUE=redis-queue:6379

BENCH_DIR=/home/frappe/frappe-bench

cd $BENCH_DIR

CURRENT_DIR=$(pwd)
INSTALLED_MARKER=/home/frappe/installed.txt

DEV_MODE=${DEV_MODE:-0}

echo "Current directory: $CURRENT_DIR"

APPS=$(find $BENCH_DIR/apps/* -maxdepth 0 -type d | xargs basename -a)

if [ "$1" = "dev" ]; then
  echo "Running in development mode."
  DEV_MODE="true"
else
  echo "Running in production mode."
  DEV_MODE="false"
fi

cd $CURRENT_DIR || exit 1

create_procfile() {
  echo "Creating Procfile..."
  echo "web: bench serve" >>Procfile
  echo "watch: bench watch" >>Procfile
  echo "worker:  bench worker 1>> logs/worker.log 2>> logs/worker.error.log" >>Procfile
}

configure_bench() {
  if [ ! -f "$INSTALLED_MARKER" ]; then
    echo "Configuring bench settings..."
    cd "$CURRENT_DIR" || exit 1
    ls -1 apps >sites/apps.txt 2>/dev/null || true
    echo "DB_HOST: $DB_HOST"
    echo "REDIS_CACHE: $REDIS_CACHE"
    echo "REDIS_CACHE: $REDIS_QUEUE"
    echo "SOCKETIO_PORT: $SOCKETIO_PORT"
    bench set-config -g db_host $DB_HOST
    bench set-config -gp db_port $DB_PORT
    bench set-config -g redis_cache "redis://$REDIS_CACHE"
    bench set-config -g redis_queue "redis://$REDIS_QUEUE"
    bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
    bench set-config -gp socketio_port $SOCKETIO_PORT
    echo "Building site (frontend) for the first time..."
    bench setup requirements
    echo "Installing apps: "
    echo $APPS | xargs basename -a | sed 's/^/- /'
    echo bench new-site frontend --force --mariadb-user-host-login-scope='%' --admin-password=$ROOT_PASSWORD --db-root-username=$ROOT_USERNAME --db-root-password=$ROOT_PASSWORD $(echo $(echo $APPS | xargs -n1 echo --install-app))
    bench new-site frontend --force --mariadb-user-host-login-scope='%' --admin-password=$ROOT_PASSWORD --db-root-username=$ROOT_USERNAME --db-root-password=$ROOT_PASSWORD $(echo $(echo $APPS | xargs -n1 echo --install-app))
    if [ "$DEV_MODE" = "true" ]; then
      echo "Development mode: Installing ERPNext app."
      bench --site frontend set-config developer_mode 1
      bench --site frontend set-config allow_tests 1
      create_procfile
    fi
    bench build
    echo "System installed." >"$INSTALLED_MARKER"
    echo "Configuration completed."
  fi
}

configure_bench

if [ "$DEV_MODE" = "true" ]; then
  bench start
else
  /home/frappe/frappe-bench/env/bin/gunicorn \
    --chdir=/home/frappe/frappe-bench/sites \
    --bind=0.0.0.0:8000 \
    --threads=4 \
    --workers=2 \
    --worker-class=gthread \
    --worker-tmp-dir=/dev/shm \
    --timeout=120 \
    --preload \
    frappe.app:application
fi
