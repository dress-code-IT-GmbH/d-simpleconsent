FROM intra/ubi8-py36
# intra/ubi8-py36 is a synonym to registry.access.redhat.com/ubi8/python-36

USER root
RUN dnf -y update \
 && dnf -y install iputils logrotate net-tools \
 && dnf clean all

# install nginx
# (Rationale: gunicorn does not serve static files. To avoid an extra deployment interface,
# nginx serves /static/ it within this container)
RUN  yum -y install nginx \
 && yum clean all
RUN mkdir -p /opt/etc/nginx /var/log/nginx/ /var/run/nginx/  \
 && chown nginx:nginx /var/log/nginx/ /var/run/nginx/
COPY install/etc/nginx /opt/etc/nginx

# install web application
ENV APPHOME=/opt/simpleconsent
COPY simpleconsent $APPHOME

WORKDIR $APPHOME
RUN python -m pip install virtualenv \
 && mkdir -p /opt/venv /var/log/webapp/ /var/run/webapp/ \
 && virtualenv /opt/venv \
 && source /opt/venv/bin/activate \
 && python -m pip install gunicorn django-mssql \
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