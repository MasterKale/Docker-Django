# DVD-R (formerly DVD)
### Docker, ~~Vagrant~~, Django, and Redis

This is a playground for me to test out getting **Django, PostgreSQL, and Redis** working together within multiple **Docker** containers. I'm also experimenting with **Vagrant** as a standardized Ubuntu 16.04 development environment and to reduce complexity/limitations associated with running Docker Engine in Windows.

## Prerequisites

TODO

## Components

### Dockerfile

This file is derived from the standard `python:3.5-onbuild` Dockerfile, only made a bit more explicit. This Dockerfile is responsible for hosting the Django project.

### docker-compose.yml

Compose is tasked with spinning up three containers: one for PostgreSQL, the above container for Django, and one for Redis. Right now Compose transparently forwards port 8000 for testing. The **django** container's `command` can be easily updated to run the Django server as a WSGI application.

### docker-compose.override.yml

TODO

### Pipfile/Pipfile.lock

Includes the PyPI packages needed to make Django, Postgre, and Redis work together.

### .env

TODO

### .editorconfig

TODO

### .flake8

TODO

### .vscode/settings.json

TODO

### _app/gunicorn.cfg

TODO

### _app/nginx.conf

TODO

## Directions

### Working with containerized Django

Django commands can be run using the `docker-compose run` command. Just specify the container name and the command that you want to run in the container.

For example, to create a new Django project, run the following command:

```
docker-compose run django django-admin.py startproject appname .
```

When the command finishes, you'll find the new project files on your local machine.

From here, you'll want to run `python manage.py` commands through `docker-compose run`:

```sh
# Create a Django app called 'test'
docker-compose run django python manage.py startapp appname
# Perform DB migrations
docker-compose run django python manage.py migrate
```

The server can be started with a simple Compose command:

```sh
$ docker-compose up
```

This will start both the **db** and **django** containers and make the Django site available locally at http://localhost.

### Specifying environment variables

For this project, a **secure.env** file has been included to demonstrate how to set a different superuser password for the **db** container (see [here](https://hub.docker.com/_/postgres/) for more postgres-specific variables).

Follow this format when adding new variables:

```
VARIABLE_NAME=value-here
```

These variables will also be available for use in the **django** container. To use them in your Django project, simply use Python's `os.getenv()`:

```py
# appname/settings.py
import os

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv("DEBUG", False) == "true"

ALLOWED_HOSTS = [
    "localhost",
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql_psycopg2",
        "NAME": os.getenv("POSTGRES_USER"),
        "USER": os.getenv("POSTGRES_USER"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD"),
        "HOST": "db",
        "PORT": 5432,
    }
}
```

The next time you run `docker-compose up` the **django** and **db** containers will both make use of the new password.

### Redis Support

An instance of Redis exists in the `redis` container. To integrate this into your Django project, first add `django_redis` to your project's `INSTALLED_APPS`:

```py
INSTALLED_APPS = [
    # ...snip...
    "django_redis",
]
```

Then, include the following in **appname/settings.py**:

```py
# django-redis
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://redis:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}
SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "default"
```
