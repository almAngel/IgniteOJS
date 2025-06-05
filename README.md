# IgniteOJS
# Open Journal Systems (OJS) Docker Setup

## Table of Contents
- [Project Description](#project-description)
- [Background](#background)
- [Keywords](#keywords)
- [Importing an Existing Project](#importing-an-existing-project)

## Project Description
This project provides a fast and easy setup for Open Journal Systems (OJS) using Docker. It is designed for scholarly publishing and academic journal management, enabling quick deployment and development of OJS environments. The repository includes Docker configurations, import scripts, and volume management to streamline OJS installation, database restoration, and file handling. Ideal for developers, journal managers, and institutions seeking an open access, containerized OJS solution with minimal setup effort.

## Background
The idea to create this repository arose from the need to introduce changes to an existing client's project, where the hosting was managed. The client requested many changes, and OJS does not handle changes easily, so I was forced to create this environment.

## Importing an Existing Project
If you already have an existing project and want to import it into this environment: copy the `private` and `public` folders and the `dump.sql` file generated after the OJS installation into the `/volumes/import` directory.

## Starting from scratch
1. Clean reset of containers:
   ```bash
   docker compose down -v
   docker compose up -d
   ```
2. Regular OJS installation: Access the OJS web interface in your browser and complete the installation process as usual.
3. Create a journal to have sample data.
4. Create a database dump from the database container and export it to the `/volumes/import` folder (using a temporary container with mysqldump):
   ```bash
   docker run --rm --network container:ojs_db_${COMPOSE_PROJECT_NAME} -e MYSQL_PWD=$OJS_DB_PASSWORD mysql:8 mysqldump --column-statistics=0 -h127.0.0.1 -u$OJS_DB_USER $OJS_DB_NAME > ./volumes/import/dump.sql
   ```
   Replace `$COMPOSE_PROJECT_NAME`, `$OJS_DB_USER`, `$OJS_DB_PASSWORD`, and `$OJS_DB_NAME` with your actual environment variable values if different.
5. Export data from inside the container:
   - From `/var/www/files` to `/volumes/import/private`:
     ```bash
     docker cp ojs_app_${COMPOSE_PROJECT_NAME}:/var/www/files/. ./volumes/import/private/
     ```
   - From `/var/www/html/public` to `/volumes/import/public`:
     ```bash
     docker cp ojs_app_${COMPOSE_PROJECT_NAME}:/var/www/html/public/. ./volumes/import/public/
     ```
   - Export the entire `/var/www/html` directory to `/volumes/html`:
     ```bash
     docker cp ojs_app_${COMPOSE_PROJECT_NAME}:/var/www/html/. ./volumes/html/
     ```
6. Uncomment the following line in your `docker-compose.yml` file to mount the exported html directory:
   ```yaml
   - ./volumes/html:/var/www/html
   ```
   This ensures that the exported `/var/www/html` directory from the container is used by the OJS service.
7. Change permissions recursively on the `html` folder to allow modifications:
   ```bash
   chmod -R 777 ./volumes/html
   ```
   This ensures you have full read/write access to the exported html directory.
8. Ready! Now you can safely develop and test your own plugins or customizations without risking your production server.

## Keywords
ojs, open journal systems, scholarly publishing, academic journal, docker, ojs development, pkp, open access, fast setup, ojs docker, ojs quickstart, igniteojs