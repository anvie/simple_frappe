#!/bin/bash
# Script ini harus dijalankan menggunakan user root di dalam docker container.
#

set -e

BENCH_DIR=/home/frappe/frappe-bench

cd $BENCH_DIR

CURRENT_DIR=$(pwd)

find_top_dirs() {
  local target_dir="$1"
  if [[ -z "$target_dir" ]]; then
    echo "Usage: find_top_dirs <dir_name>" >&2
    return 1
  fi

  find . -type d -name "$target_dir" ! -name "*.bak" | awk -v target="$target_dir" '
  {
    # Skip if directory ends with .bak (extra safety if path has .bak somewhere)
    if ($0 ~ "\\.bak$") next

    for (i in seen) {
      if (index($0, seen[i]) == 1 && $0 != seen[i]) next
      if (index(seen[i], $0) == 1 && seen[i] != $0) delete seen[i]
    }
    seen[++n] = $0
  }
  END {
    for (i = 1; i <= n; i++) print seen[i]
  }
  '
}

make_pths() {
  # Setup pth files (ini diperlukan agar setiap app yg ada di apps/ bisa di-import dalam virtual environment).
  ls -1 "$BENCH_DIR/apps" >sites/apps.txt
  while IFS= read -r line; do
    if [ -z "$line" ]; then
      continue
    fi

    name=$(echo "$line" | xargs)

    filename="$BENCH_DIR/env/lib/python3.11/site-packages/${name}.pth"

    echo "Linking pth apps/$name ..."

    echo "$BENCH_DIR/apps/$name" >"$filename"

    echo "Linking done."
  done <sites/apps.txt
}

make_link() {
  local dir=$1
  safe_dir=$(echo "$dir" | sed 's|^\.\/|/deps/|')
  echo "$safe_dir"
  safe_dir_name=$(dirname "$safe_dir")
  mkdir -p "$safe_dir_name"
  if [ ! -d "$dir" ]; then
    return 0
  fi
  mv "$dir" "$safe_dir"
  echo "Creating symbolic link for $dir from $safe_dir"
  ln -s "$safe_dir" "$dir"
}

configure_system() {
  local symlink_path="/usr/bin/sup"
  local target_cmd="/usr/bin/supervisorctl"
  local bashrc_file="$HOME/.bashrc"
  local tail_function="tail_all(){ tail -f /var/log/*.log; }"
  local tail_nginx="tail_nginx(){ tail -f /var/log/nginx.log; }"
  local tail_backend="tail_backend(){ tail -f /var/log/backend.log; }"

  if ! grep -q "^tail_all()" "$bashrc_file"; then

    echo "Configuring system..."

    mkdir -p /var/log/supervisor
    mkdir -p /var/log/nginx

    if [ ! -e "$target_cmd" ]; then
      echo "Warning: $target_cmd not found. Skipping sup symlink creation." >&2
    else
      if [ -L "$symlink_path" ] || [ -e "$symlink_path" ]; then
        echo "Sup symlink already exists at $symlink_path"
      else
        if ln -s "$target_cmd" "$symlink_path"; then
          echo "Created symlink: $symlink_path -> $target_cmd"
        else
          echo "Error creating symlink $symlink_path" >&2
        fi
      fi
    fi

    {
      echo ""
      echo "# Custom function to tail logs"
      echo "$tail_function"
      echo "$tail_nginx"
      echo "$tail_backend"
    } >>"$bashrc_file"
    echo "Added helper function to $bashrc_file"
  fi
}

make_common_site_config() {
  mkdir -p $BENCH_DIR/sites
  if [ ! -f $BENCH_DIR/sites/common_site_config.json ]; then
    echo "{}" >$BENCH_DIR/sites/common_site_config.json
  fi
}

set_permissions() {
  echo "Setting permissions..."
  chown -R frappe:frappe $BENCH_DIR/sites
  chown -R frappe:frappe $BENCH_DIR/apps
}

echo "Preparing the environment..."

make_common_site_config
configure_system
make_pths
set_permissions
