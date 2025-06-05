#!/bin/bash

# Load environment variables from .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Variables
CONTAINER_NAME="ojs_app_${COMPOSE_PROJECT_NAME:-demo}"
DB_CONTAINER="ojs_db_${COMPOSE_PROJECT_NAME:-demo}"

# Copy private and public folders into the OJS container
echo "Starting OJS import..."
if [ -z "$COMPOSE_PROJECT_NAME" ]; then
  echo "Error: COMPOSE_PROJECT_NAME is not defined. Please set an environment variable."
  exit 1
fi
if [ -z "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  echo "Error: The container $CONTAINER_NAME is not running."
  exit 1
fi
if [ -z "$(docker ps -q -f name=$DB_CONTAINER)" ]; then
  echo "Error: The database container $DB_CONTAINER is not running."
  exit 1
fi
if [ ! -d "./volumes/import/private" ] || [ ! -d "./volumes/import/public" ]; then
  echo "Error: The folders ./volumes/import/private and ./volumes/import/public must exist."
  exit 1
fi
echo "Copying private folder to container..."
docker cp ./volumes/import/private/. $CONTAINER_NAME:/var/www/files/

echo "Copying public folder to container..."
docker cp ./volumes/import/public/. $CONTAINER_NAME:/var/www/html/public/

echo "Restoring database..."
docker exec -i $DB_CONTAINER mariadb -u"$OJS_DB_USER" -p"$OJS_DB_PASSWORD" "$OJS_DB_NAME" < ./volumes/import/dump.sql

# Change the value of 'installed' to 'On' in config.inc.php inside the container
docker exec $CONTAINER_NAME sed -i 's/^\(installed *= *\)Off/\1On/' /var/www/html/config.inc.php

# Change the database values in config.inc.php inside the container
docker exec $CONTAINER_NAME sed -i 's/^driver *= *.*/driver = mysqli/' /var/www/html/config.inc.php
docker exec $CONTAINER_NAME sed -i 's/^host *= *.*/host = '"$OJS_DB_HOST"'/' /var/www/html/config.inc.php
docker exec $CONTAINER_NAME sed -i 's/^username *= *.*/username = '"$OJS_DB_USER"'/' /var/www/html/config.inc.php
docker exec $CONTAINER_NAME sed -i 's/^password *= *.*/password = '"$OJS_DB_PASSWORD"'/' /var/www/html/config.inc.php
docker exec $CONTAINER_NAME sed -i 's/^name *= *.*/name = '"$OJS_DB_NAME"'/' /var/www/html/config.inc.php

# Restart the OJS container to apply the changes
docker restart $CONTAINER_NAME
echo "Database restored and configuration updated."
# Wait for the OJS container to be fully restarted
sleep 10
# Check the status of the OJS container
if [ "$(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME)" != "true" ]; then
  echo "Error: The container $CONTAINER_NAME did not restart correctly."
  exit 1
fi
# Check if the OJS container is running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  echo "The container $CONTAINER_NAME is running."
else
  echo "Error: The container $CONTAINER_NAME is not running after restart."
  exit 1
fi
# Check if the database has been restored successfully
if docker exec $DB_CONTAINER mariadb -u"$OJS_DB_USER" -p"$OJS_DB_PASSWORD" -e "USE $OJS_DB_NAME; SHOW TABLES;" > /dev/null 2>&1; then
  echo "The database has been restored successfully."
else
  echo "Error: The database has not been restored successfully."
  exit 1
fi
# Check if the folders have been copied successfully
if docker exec $CONTAINER_NAME ls /var/www/files > /dev/null 2>&1 && docker exec $CONTAINER_NAME ls /var/www/html/public > /dev/null 2>&1; then
  echo "The private and public folders have been copied successfully."
else
  echo "Error: The private and public folders have not been copied successfully."
  exit 1
fi
# Finish the script
echo "OJS import completed successfully."
# Final Message
echo "Import completed!"