#!/bin/bash

scriptdir=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)


main() {
    start_appserver
    start_reverse_proxy
    keep_running
    trap propagate_signals SIGTERM
}


start_appserver() {
    echo "starting gunicorn"
    # set default charset for python 3
    export LC_ALL="en_US.UTF-8"
    export LANG="en_US.UTF-8"
    # settings.py/INSTALLED_APPS controls which webapps are serviced in this instance
    source /etc/profile.d/py_venv.sh
    export PYTHONPATH=$APPHOME:$APPHOME/simpleconsent
    # missing error message "worker failed ot boot"? add --preload option
    mkdir -p /var/run/webapp/
    gunicorn --config=/opt/etc/gunicorn/config.py simpleconsent.wsgi:application --pid /var/run/webapp/gunicorn.pid &
}


start_reverse_proxy() {
    # start nginx (used to serve static files)
    /usr/sbin/nginx -c /opt/etc/nginx/nginx.conf
}


keep_running() {
    echo 'wait for SIGINT/SIGKILL'
    while true; do sleep 36000; done
    echo 'interrupted; exiting shell -> may exit the container'
}


propagate_signals() {
    kill -s SIGTERM $(cat /var/run/webapp/gunicorn.pid)
    kill -s SIGQUIT $(cat /var/run/nginx/nginx.pid)
}


main $@
