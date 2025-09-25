#!/bin/bash
# Bench wrapper script for Frappe Docker
# This script simplifies running bench commands in the Docker container from the host machine.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME=""
COMPOSE_FILE=""
SHOW_HELP=0

while [[ $# -gt 0 ]]; do
  case $1 in
  -p | --project)
    PROJECT_NAME="$2"
    shift 2
    ;;
  -f | --file)
    COMPOSE_FILE="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

if [ $SHOW_HELP -eq 1 ] || [ $# -eq 0 ]; then
  show_help
  exit 0
fi

DOCKER_CMD="docker compose"
if [ -n "$COMPOSE_FILE" ]; then
  DOCKER_CMD="$DOCKER_CMD -f $COMPOSE_FILE"
fi
if [ -n "$PROJECT_NAME" ]; then
  DOCKER_CMD="$DOCKER_CMD -p $PROJECT_NAME"
fi

# Check if frappe container is running
if ! $DOCKER_CMD ps --quiet frappe 2>/dev/null | grep -q .; then
  echo -e "${RED}Error: Backend container is not running${NC}"
  echo -e "${YELLOW}Start containers with: docker compose up -d${NC}"
  exit 1
fi

echo -e "${GREEN}Executing: bench $@${NC}"
$DOCKER_CMD exec -u frappe frappe bench "$@"

