# DVD-R (a.k.a. DVD)
### Docker, Vagrant, Django, and Redis

This is a playground for me to test out getting **Django, PostgreSQL, and Redis** working together within multiple **Docker** containers. I'm also experimenting with **Vagrant** as a standardized Ubuntu 16.04 development environment and to reduce complexity/limitations associated with running Docker Engine in Windows.

## Components

### Vagrantfile

Vagrant is a basic Ubuntu 16.04/`xenial64` image with a few customizations:

* Install Docker prereqs
* Install linux-image-extra for aufs support
* Install Docker
* Install Docker-Compose
* Miscellaneous Docker-related setup steps
* Create the alias `dc` for `docker-compose`

### Dockerfile

This file is derived from the standard `python:3.5-onbuild` Dockerfile, only made a bit more explicit. This Dockerfile is responsible for hosting the Django project.

### docker-compose.yml

Compose is tasked with spinning up three containers: one for PostgreSQL, the above container for Django, and one for Redis. Right now Compose transparently forwards port 8000 for testing. The `web` container's `command` can be easily updated to run the Django server as a WSGI application.

### requirements.txt

Includes the PyPI packages needed to make Django, Postgre, and Redis work together.

## Directions

### Booting up Vagrant

Vagrant is intended for local development. To get started, [install Vagrant](https://www.vagrantup.com/docs/installation/) and either [Hyper-V](https://blogs.technet.microsoft.com/canitpro/2015/09/08/step-by-step-enabling-hyper-v-for-use-on-windows-10/) (Windows-only) or [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (all platforms).

> NOTE: Go into the `Vagrantfile` and comment out the provider you *won't* be using. You'll find basic providers for both Hyper-V and VirtualBox.

Start the VM to begin:

    vagrant up

Once the VM is up, you can use the `vagrant ssh` command (on Linux) or PuTTY (on Windows) to remote into the machine.

> NOTE: If you remote in using an ssh client, the default login **username** and **password** should be **vagrant** and **vagrant** respectively

The folder containing this cloned repo will be mapped to `/home/ubuntu/data/`. You'll start in `/home/ubuntu/`, so just `cd data` to jump into the folder containing the Docker, Vagrant, and Django files. From here, you can use `docker-compose` to run commands within either container.

> NOTE: Django is contained within the `web` container, while PostgreSQL is in the `db` container.

### Working with containerized Django

Django commands can be run using the `docker-compose run` command. Just specify the container name and the command that you want to run in the container.

For example, to create a new Django project, run the following command:

    docker-compose run web django-admin.py startproject composeexample .

When the command finishes, you'll find the new project files on your local machine. Thanks to the mapped drive they'll also appear in Vagrant.

> NOTE: The bash alias `dc` has been added to Vagrant to cut down on the number of times you have to type `docker-compose`.

Before you proceed any further, go ahead and update the new project to use the Postgres database in the `db` container:

    # composeexample/settings.py
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'NAME': 'postgres',
            'USER': 'postgres',
            'HOST': 'db',
            'PORT': 5432,
        }
    }

From here, you'll want to run `python manage.py` commands through `docker-compose run`:

    # Create a Django app called 'test'
    docker-compose run web python manage.py startapp test
    # Perform DB migrations
    docker-compose run web python manage.py migrate

While you *can* run `docker-compose run web python manage.py runserver` to start the Django server for local development, you'll want to use Compose to start the actual server in a production environment:

    docker-compose up

This will start both the `db` and `web` containers and make the Django site available locally at http://localhost:8000.

### Specifying environment variables

Environment variables can be declared within `.env` files and assigned to services using the `env_file` key for a particular service:

    services:
      db:
        image: postgres
        env_file: secure.env

For this project, a `secure.env` file has been included to demonstrate how to set a different superuser password for the `db` container (see [here](https://hub.docker.com/_/postgres/) for more postgres-specific variables).

Follow this format when adding new variables:

    VARIABLE_NAME="value-here"

These variables will also be available for use in the `web` container. To use them in your Django project, simply use `os.getenv()`:

    import os

    # composeexample/settings.py
    DATABASES = {
        'default': {
            ...
            'PASS': os.getenv('POSTGRES_PASSWORD')
            ...
        }
    }

The next time you run `docker-compose up` the `web` and `db` containers will both make use of the new password.

### Redis Support

An instance of Redis exists in the `redis` container. To integrate this into your Django project, add `django_redis` to your project's `INSTALLED_APPS` and include the following in `settings.py`:

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

