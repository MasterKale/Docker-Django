# Docker'd Django
### Django, Postgres, and Redis, all in Docker

This is a boilerplate repo intended for quickly starting a new **Django** project with **PostgreSQL** and **Redis** support, all running within Docker containers.

Multiple production hosting options are also included. See the **Production Hosting** section below for more information.

- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Components](#components)
- [Production Hosting](#production-hosting)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker
- Pipenv
  - Make sure Python3 is available
  - Enables `pipenv install` to set up libraries locally for the editor to crawl. The Django container also uses Pipenv to install dependencies to encourage use of this new Python package management tool.

## Getting started

1. Clone this repo
2. Delete the **.git** folder
    - `rm -rf .git/`
3. Create a new git repo
    - `git init`
    - `git add .`
    - `git commit -m "Initial Commit"`
4. Install Python dependencies in a Python3 virtual environment
    - `pipenv install --three`
5. Create a new Django project
    - `pipenv run django-admin startproject appname _app/`
6. Make the following changes to your Django project's **settings.py**:

```py
# appname/settings.py
import os

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', False) == 'true'

# Enable traffic and form submissions from localhost and PROD_HOST_NAME
ALLOWED_HOSTS = ['localhost']
CSRF_TRUSTED_ORIGINS = ['http://localhost']

PROD_HOST_NAME = os.getenv('PROD_HOST_NAME', None)
if PROD_HOST_NAME:
    ALLOWED_HOSTS.append(PROD_HOST_NAME)
    CSRF_TRUSTED_ORIGINS.append(f'https://{PROD_HOST_NAME}')

# Point Django to Docker-hosted Postgres
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': os.getenv('POSTGRES_USER'),
        'USER': os.getenv('POSTGRES_USER'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD'),
        'HOST': 'db',
        'PORT': 5432,
    }
}

# Set up static files
STATIC_ROOT = 'static'

# Redis cache support
# https://docs.djangoproject.com/en/4.0/topics/cache/#redis-1

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
    }
}
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```

7. Update the **.env** file to specify values for the environment variables defined within
8. Do a global search of all files here for "appname" and replace it with the actual name of your app
9. Start Django for development at http://localhost:8000
    - `docker compose up`

## Components

### Dockerfile

Builds the Django container. The container is built from a standard **python** Docker image and will run Django's `colletstatic` when being built.

### docker-compose.yml + docker-compose.dev.yml

Use `./start-dev.sh` to start Django for development. This will spin up three containers: the above container for **Django**, one for **PostgreSQL**, and one for **Redis**.

Django can be accessed in DEBUG mode directly from http://localhost:8000 during development. The Gunicorn workers are set to reload when file changes are detected.

Postgres can also be directly accessed at `localhost:5432` using the credentials you specified in the **.env** file.

### docker-compose.yml + docker-compose.prod.yml

See the **Production Hosting** section below for more information.

Use `./start-dev.sh` to start Django for production. You can also run `./update-prod-django.sh` whenever you need to deploy a new build.

### Pipfile/Pipfile.lock

Includes Python packages needed to make Django, Postgre, and Redis work together.

### .env

Contains environment variables for the containers. Several variables are included for configuring Postgres and Django secrets.

### .dockerignore

Defines files that Docker should _never_ include when building the Django image.

### .editorconfig

Defines some common settings to help ensure consistency of styling across files.

### .flake8

Configures the **flake8** Python linter. Includes a few common settings to my personal preferences.

### .vscode/settings.json

Helps configure the Python plugin to lint with flake8. A placeholder Python interpreter setting is left in to simplify pointing to the local virtual environment created with Pipenv.

### _app/gunicorn.cfg.py

Defines settings for gunicorn, including a port binding, workers, and a gunicorn-specific error log.

### _caddy/Caddyfile

Establishes a reverse-proxy to Django, and serves Django static files using [Caddy](https://caddyserver.com/v2). See **Production Hosting** below for more info.

## Production Hosting

This project includes two options for handling production hosting, including reverse-proxying Django and handling SSL:

1. Use [Caddy](https://caddyserver.com/v2)
2. Use [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

**You'll only need one of these!** Which ever option you choose below, delete the other commented-out service in **docker-compose.prod.yml**.

### Option 1: Use Caddy

Follow these steps:

1. Uncomment the `caddy` service in **docker-compose.prod.yml**
2. Uncomment all `volumes` in **docker-compose.prod.yml**
3. Uncomment the `static_files_volume:...` entry in `django` service's `volumes` property in **docker-compose.prod.yml**
4. Find the two lines in **./update-prod-django.sh** ending in "caddy" and follow the instructions above them to include the `caddy` service in the production update process.
5. Configure your server's firewall to expose TCP for ports 80 and 443, and UDP for port 443. These will allow Caddy to host the site, and generate and periodically update SSL certificates for the site via Let's Encrypt.

When these steps are complete, running **start-prod.sh** should make Django available on the public internet at `https://$PROD_HOST_NAME`.

### Option 2: Use Cloudflare Tunnel

Uncomment the `cloudflaretunnel` service in **docker-compose.prod.yml** and then follow these steps:

1. Log into the [Cloudflare Zero Trust dashboard](https://dash.teams.cloudflare.com/)
2. Click **Access > Tunnels**
3. Click **Create a tunnel**
4. Specify a **Tunnel name**
5. Click **Docker** on the **Install connector** step
6. Save the value of the `--token` flag in the page's `docker` command to this project's **.env** file as the `CLOUDFLARE_TUNNEL_TOKEN` environment variable
7. Run **start-prod.sh** to start the tunnel and display an entry under **Connectors**
8. Click **Next**
9. Set up a **Public hostname**
10. For the **Service** select "**HTTP**" and then enter "**django:8000**"
11. Click **Save &lt;tunnel name&gt; tunnel** to complete setup
12. Set the `PROD_HOST_NAME` variable in the **.env** file to the tunnel's configured **Public hostname**

You will also need to make the following change to Django's **_app/appname/settings.py** to set up whitenoise to handle static files:

```py
INSTALLED_APPS = [
    # ...
    # See http://whitenoise.evans.io/en/latest/django.html#using-whitenoise-in-development
    "whitenoise.runserver_nostatic",
    "django.contrib.staticfiles",
    # ...
]

MIDDLEWARE = [
    # ...
    "django.middleware.security.SecurityMiddleware",
    # See http://whitenoise.evans.io/en/latest/django.html#enable-whitenoise
    "whitenoise.middleware.WhiteNoiseMiddleware",
    # ...
]

# See http://whitenoise.evans.io/en/latest/django.html#enable-whitenoise
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
```

When these steps are complete, running **start-prod.sh** should make Django available on the public internet at `https://$PROD_HOST_NAME`. No firewall ports need to be opened on the production host, and in fact you may wish to set up the firewall to block all incoming traffic for good measure.

## Troubleshooting

### The Django container reports "exited with code 3"

You probably forgot to replace the string "appname" with the actual name you passed to `django-admin startproject`. Check **_app/gunicorn_appname.log** to see if Gunicorn is erroring out with something like this:

```
ModuleNotFoundError: No module named 'appname'
```
