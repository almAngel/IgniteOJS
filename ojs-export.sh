#!/bin/bash

# ojs-export.sh - Export OJS data and files for migration or backup
# Usage: Run this script from the root of your OJS Docker project

set -e

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Set variables
CONTAINER_NAME="ojs_app_${COMPOSE_PROJECT_NAME}"
DB_CONTAINER="ojs_db_${COMPOSE_PROJECT_NAME}"

# 1. Clean reset of containers (optional, uncomment if needed)
# docker compose down -v
# docker compose up -d

# 2. (Manual) Complete OJS installation and create a journal via the web interface before running this script

# 3. (Manual) Create a journal to have sample data before running this script

# 4. Export database dump using a temporary container with mysqldump
if [ -z "$OJS_DB_USER" ] || [ -z "$OJS_DB_PASSWORD" ] || [ -z "$OJS_DB_NAME" ]; then
  echo "Error: OJS_DB_USER, OJS_DB_PASSWORD, or OJS_DB_NAME is not set."
  exit 1
fi

echo "Exporting database to ./volumes/import/dump.sql ..."
docker run --rm --network container:$DB_CONTAINER -e MYSQL_PWD=$OJS_DB_PASSWORD mysql:8 mysqldump --column-statistics=0 -h127.0.0.1 -u$OJS_DB_USER $OJS_DB_NAME > ./volumes/import/dump.sql

echo "Exporting private files..."
docker cp $CONTAINER_NAME:/var/www/files/. ./volumes/import/private/

echo "Exporting public files..."
docker cp $CONTAINER_NAME:/var/www/html/public/. ./volumes/import/public/

echo "Exporting entire html directory..."
docker cp $CONTAINER_NAME:/var/www/html/. ./volumes/html/

echo "Setting permissions on ./volumes/html ..."
chmod -R 777 ./volumes/html

echo "Export completed! Now uncomment the following line in your docker-compose.yml if you want to mount the exported html directory:"
echo "  - ./volumes/html:/var/www/html"
