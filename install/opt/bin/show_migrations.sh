#!/bin/bash

export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

source /etc/profile.d/py_venv.sh
export PYTHONPATH=$APPHOME:$APPHOME/simpleconsent
python manage.py make_migrations