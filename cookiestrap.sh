#!/usr/bin/env bash

############################################################################### 
############################################################################### 
# You should customize all of these.

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

# You shouldn't need to edit anything below this line.
############################################################################### 
############################################################################### 

start_seconds="$(date +%s)"
echo "Welcome to https://github.com/kappataumu/vagrant-django-cookie-dough"

ping_result="$(ping -c 2 8.8.4.4 2>&1)"
if [[ $ping_result != *bytes?from* ]]; then
	echo "Network connection unavailable. Try again later."
	exit 1
fi

apt_packages=(
	vim
	curl
	git-core
	nodejs
	
	# Extra stuff, in case you want to SSH to the machine and work interactively
	tmux
	byobu
	
	# These are the pyenv requirements, see
	# https://github.com/yyuu/pyenv/wiki/Common-build-problems#requirements
	make
	build-essential 
	libssl-dev 
	zlib1g-dev 
	libbz2-dev 
	libreadline-dev 
	libsqlite3-dev 
	llvm
	
	postgresql-9.5 
	
	# Needed for Python deps
	libpq-dev  # psycopg2
	libjpeg-dev  # Pillow: https://github.com/python-pillow/Pillow/issues/1275#issuecomment-185775965
)

# Needed for nodejs.
# https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
curl -sSL https://deb.nodesource.com/setup_4.x | sudo -E bash -
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo add-apt-repository -y ppa:git-core/ppa
sudo add-apt-repository -y ppa:nginx/stable
sudo add-apt-repository -y ppa:pi-rho/dev
sudo add-apt-repository -y ppa:byobu/ppa
sudo add-apt-repository -y "deb https://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"

sudo apt-get update
sudo apt-get upgrade

echo "Installing packages..."
sudo apt-get install -y ${apt_packages[@]}
sudo apt-get clean

# Install and configure pyenv and pyenv-virtualenv
git clone https://github.com/yyuu/pyenv.git /home/vagrant/.pyenv
git clone https://github.com/yyuu/pyenv-virtualenv.git /home/vagrant/.pyenv/plugins/pyenv-virtualenv

export PYENV_ROOT="/home/vagrant/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

pyenv install 3.5.1
pyenv virtualenv 3.5.1 "$domain_name"

if [[ ! -d "/srv/www/$domain_name" ]]; then
	mkdir "/srv/www/$domain_name"
	mkdir "/srv/www/$domain_name/logs"
fi
 
cd "/srv/www/$domain_name"
pyenv local "$domain_name"

# Install cookiecutter and configure cookiecutter-django
pip install git+https://github.com/audreyr/cookiecutter.git@master
cookiecutter --no-input https://github.com/pydanny/cookiecutter-django "${cookiecutter_options[@]}"

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $project_slug; then
	echo "PostgreSQL database exists. Skipping setup."
else
	sudo -u postgres psql -c "CREATE DATABASE $project_slug"
	sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_password'"
	sudo -u postgres psql -c "ALTER ROLE $db_user SET client_encoding TO 'utf8'"
	sudo -u postgres psql -c "ALTER ROLE $db_user SET default_transaction_isolation TO 'read committed'"
	sudo -u postgres psql -c "ALTER ROLE $db_user SET timezone TO 'UTC'"
	sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $project_slug TO $db_user"
fi

cd "/srv/www/$domain_name/$project_slug"

pip install -r requirements/local.txt

# TODO Add this to .env, inject .env env vars in the shell
export DATABASE_URL="postgres://$db_user:$db_password@127.0.0.1:5432/$project_slug"

python manage.py migrate

if [[ -f 'Gruntfile.js' ]]; then
	# No symlinks, important for Vagrant on Windows
	npm install --no-bin-links  
	sudo npm install --global grunt-cli
	cmd_js_task="/usr/bin/grunt --gruntfile=/srv/www/$domain_name/$project_slug/Gruntfile.js watch > /srv/www/$domain_name/logs/taskrunner.log 2>&1"
fi

if [[ -f 'gulpfile.js' ]]; then
	# No symlinks, important for Vagrant on Windows
	npm install --no-bin-links  
	npm install --global gulp-cli
	# TODO Verify that gulp actually works
	cmd_js_task="gulp --gulpfile /srv/www/$domain_name/$project_slug/gulpfile.js >> /srv/www/$domain_name/logs/taskrunner.log 2>&1 &"
fi

cmd_runserver="/home/vagrant/.pyenv/versions/example.com/bin/python /srv/www/$domain_name/$project_slug/manage.py runserver 0.0.0.0:8000 > /srv/www/$domain_name/logs/runserver.log 2>&1"

eval "$cmd_runserver &"
eval "$cmd_js_task &"

# Add Upstart job for starting Django's development server
cat << DJANGO | sudo tee /etc/init/django.conf > /dev/null
description "Django"
author "kappataumu <hello@kappataumu.com>"

start on vagrant-mounted MOUNTPOINT=/srv/www
stop on shutdown

script
	export DATABASE_URL="postgres://$db_user:$db_password@127.0.0.1:5432/$project_slug"
	exec $cmd_runserver
end script

DJANGO

# Add Upstart job for starting Grunt or Gulp
if [[ -f 'Gruntfile.js' ]] || [[ -f 'gulpfile.js' ]]; then

	cat <<- TASKRUNNER | sudo tee /etc/init/taskrunner.conf > /dev/null
	description "Taskrunner"
	author "kappataumu <hello@kappataumu.com>"
	
	start on vagrant-mounted MOUNTPOINT=/srv/www
	stop on shutdown
	
	exec $cmd_js_task
	
	TASKRUNNER

fi

end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$(expr $end_seconds - $start_seconds)" seconds"
