# Vagrant box to jump-start Django projects

Effortlessly bootstrap new Django projects, using [Vagrant](https://www.vagrantup.com/) and [Cookiecutter Django](https://github.com/pydanny/cookiecutter-django).

## Features

* Vagrantfile for Ubuntu Trusty (14.04.04 LTS) VirtualBox VM.
* Isolated Python 3.5.1 virtualenv using [pyenv](https://github.com/yyuu/pyenv) and [pyenv-virtualenv](https://github.com/yyuu/pyenv-virtualenv).
* Cookiecutter Django project dependencies `pip install`ed, suitable for *development*.
* Fully operational PostgreSQL database, with the same name as the `project slug`.
* Completely hands-off. After running `vagrant up` simply browse to `http://localhost:8000` to see the live app.
* Extra features, courtesy of Cookiecutter Django:
	
	* If you opted for Grunt:
		* LiveReload support (just install the [appropriate extension](http://livereload.com/extensions/))
		* Automatic Sass compilation
		* CSS autoprefixing and minification
	
	* Alternatively, if you opted for Gulp:
		* LiveReload support (just install the [appropriate extension](http://livereload.com/extensions/))
		* Automatic Sass compilation
		* CSS autoprefixing and minification
		* Javascript minification (everything in `/static/js`)
		* Lossless image optimization (everything in `/static/images`)


## Usage

```bash
$ git clone https://github.com/kappataumu/vagrant-django-cookie-dough
$ cd vagrant-django-cookie-dough
$ vim cookiestrap.sh
```

```bash
# You should now customize all of these.

domain_name="example.com"
project_slug="cookiestrap"
db_user='db_user'
db_password='db_pass'

cookiecutter_options=(
    "project_name=My project name"
    "project_slug=$project_slug"
    "author_name=Your Name"
    "email=Your email"
    "description=A short description of the project."
    "domain_name=$domain_name"
    "version=0.1.0"
    "timezone=UTC"
    "use_whitenoise=y"
    "use_celery=n"
    "use_mailhog=n"
    "use_sentry_for_error_reporting=n"
    "use_opbeat=n"
    "use_pycharm=n"
    "windows=n"
    "use_python2=n"
    "use_docker=n"
    "use_heroku=n"
    "js_task_runner=Grunt"
    "use_lets_encrypt=n"
    "open_source_license=MIT"
)
```
```bash
$ vagrant up
```

There's a blog post as well, see [Jump-starting Django projects with Vagrant and Cookiecutter]().