#!/bin/bash

scriptdir=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)


main() {
    start_appserver
    keep_running
    trap propagate_signals SIGTERM
}


start_appserver() {
    echo "starting gunicorn"
    # settings.py/INSTALLED_APPS controls which webapps are serviced in this instance
    source /etc/profile.d/pv_venv.sh
    export PYTHONPATH=$APPHOME:$APPHOME/PVZDlib
    # missing error message "worker failed ot boot"? add --preload option
    mkdir -p /var/run/webapp/
    gunicorn --config=/opt/etc/gunicorn/webapp_config.py simpleconsent.wsgi:application --pid /var/run/webapp/gunicorn.pid &
}


keep_running() {
    echo 'wait for SIGINT/SIGKILL'
    while true; do sleep 36000; done
    echo 'interrupted; exiting shell -> may exit the container'
}


propagate_signals() {
    kill -s SIGTERM $(cat /var/run/webapp/gunicorn.pid)
}


main $@
