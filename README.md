# IgniteOJS
# Open Journal Systems (OJS) Docker Setup

## Table of Contents
- [Project Description](#project-description)
- [Background](#background)
- [Importing an Existing Project](#importing-an-existing-project)
- [Starting from scratch](#starting-from-scratch)
- [Bonus: Automated Export Script](#bonus-automated-export-script)
- [Related LinkedIn Post](#related-linkedin-post)
- [Connect](#connect)
  - [Who am I?](#who-am-i)
- [Common Errors and Solutions](#common-errors-and-solutions)
- [Keywords](#keywords)

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

## Bonus: Automated Export Script

**🚨 BONUS: Automated Export Script! (BETA) 🚨**

We have included a script called `ojs-export.sh` that automates the export steps described in the "Starting from scratch" section above. This script will:
- Export your database
- Export your private and public files
- Export the entire html directory
- Set the correct permissions automatically

⚠️ **IMPORTANT:** You must still perform the manual steps first (OJS installation and journal creation via the web interface) before running the script. The script assumes your OJS instance is already set up and running.

To use it, simply run:
```bash
bash ojs-export.sh
```

This will save you time and help avoid mistakes during the export process!

## Related LinkedIn Post

🔗 **Check out the announcement and discussion about this project on LinkedIn:**  
[IgniteOJS on LinkedIn](https://www.linkedin.com/posts/angellopezmolina_github-almangeligniteojs-igniteojs-is-activity-7336332668684398592-pU0g?utm_source=share&utm_medium=member_desktop&rcm=ACoAACAQf34B-_dlrGkByvWQv1hWwvJka_3GsHU)

Feel free to join the conversation, leave your feedback, or share your experience with IgniteOJS!

## Connect

👉 **[Connect with the author on LinkedIn!](https://www.linkedin.com/in/angellopezmolina/)** 👈

### Who am I?

I am a Software Developer based in Málaga, with experience in multiple programming languages and technologies. I am passionate about creating robust software and scalable solutions, always with a self-taught and scientific mindset. My approach is practical, focusing on the choice of technologies and the design of efficient solutions, with knowledge of basic architecture and participation in technical decisions aimed at solving real-world problems.

You can find more about my professional background, projects, and contributions on my [LinkedIn profile](https://www.linkedin.com/in/angellopezmolina/).

## Common Errors and Solutions

### Error: The directory specified for uploaded files does not exist or is not writable

**Symptom:**  
OJS displays an error during installation "Errors occurred during installation: The directory specified for uploaded files does not exist or is not writable".

**Cause:**  
The user running the container does not have the necessary read/write permissions on the mounted `./volumes` directories.

**Solution:**  
Ensure the correct permissions are set by running:

```bash
chmod -R 777 ./volumes
```

This will grant full read/write access to the `volumes` directory and its contents.  
**Note:** For production environments, adjust permissions according to your security requirements.

## Keywords
ojs, open journal systems, scholarly publishing, academic journal, docker, ojs development, pkp, open access, fast setup, ojs docker, ojs quickstart, igniteojs, containerization, php, mysql, mariadb, journal migration, scholarly communication, research publishing, open source, journal hosting, scientific publishing, journal workflow, plugin development, ojs backup, ojs restore

---