FROM intra/ubi8-py36

USER root
RUN dnf -y update \
 && dnf -y install iputils logrotate net-tools \
 && dnf clean all

# install web application
ENV APPHOME=/opt/simpleconsent
COPY simpleconsent $APPHOME

WORKDIR $APPHOME
RUN python -m pip install virtualenv \
 && mkdir -p /opt/venv /var/log/webapp/ /var/run/webapp/ \
 && virtualenv /opt/venv \
 && source /opt/venv/bin/activate \
 && python -m pip install gunicorn \
 && python -m pip install -r $APPHOME/requirements.txt \
 && python setup.py install
COPY install/etc/profile.d/py_venv.sh /etc/profile.d/py_venv.sh

# install custom config and scripts
COPY install/opt /opt
RUN chmod +x /opt/bin/*

# dcshell build number generation
COPY install/opt/bin/manifest2.sh /opt/bin/manifest2.sh
RUN chmod +x /opt/bin/manifest2.sh \
 && mkdir -p $HOME/.config/pip \
 && printf "[global]\ndisable-pip-version-check = True\n" > $HOME/.config/pip/pip.conf

COPY install/etc/logrotate /opt/etc/logrotate

VOLUME /opt/etc \
       /var/log
EXPOSE 8080
SHELL ["/bin/bash", "-l", "-c"]