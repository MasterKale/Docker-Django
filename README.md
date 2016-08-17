# DVD
Docker, Vagrant, and Django

This is a playground for me to test out getting **Django + PostgreSQL** working within **Docker** containers. I'm also experimenting with **Vagrant** as a standardized Ubuntu 16.04 development environment and to reduce complexity/limitations associated with running Docker Engine in Windows.

## Components

### Vagrantfile

Vagrant is a basic Ubuntu 16.04/`xenial64` image with a few customizations:

* Install Docker prereqs
* Install linux-image-extra for aufs support
* Install Docker
* Install Docker-Compose
* Miscellaneous Docker-related setup steps

### Dockerfile

This file is derived from the standard `python:3.5-onbuild` Dockerfile, only made a bit more explicit. This Dockerfile is responsible for hosting the Django project.

### docker-compose.yml

Compose is tasked with spinning up two containers: one for PostgreSQL, and the above container for Django. Right now it just transparently forwards port 8000 for testing. The container's `command` can be easily updated to run the server as a WSGI application.

### requirements.txt

A barebones Django + PostgreSQL app can be started with just two Python packages: `Django`, and `psycopg2`.

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