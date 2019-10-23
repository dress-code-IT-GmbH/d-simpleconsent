FROM intra/centos7_py37_base

USER root
RUN yum -y update \
 && yum -y install epel-release \
 && yum -y install gcc-c++ iputils logrotate net-tools \
 && yum clean all

# install nginx
# (Rationale: gunicorn does not serve static files. To avoid an extra deployment interface,
# nginx serves /static/ it within this container)
RUN  yum -y install nginx \
 && yum clean all \
 && mkdir -p /opt/etc/nginx /var/log/nginx/ /var/run/nginx/  \
 && chown nginx:nginx /var/log/nginx/ /var/run/nginx/
COPY install/etc/nginx /opt/etc/nginx

# install web application
ENV APPHOME=/opt/simpleconsent
COPY simpleconsent $APPHOME

WORKDIR $APPHOME
ENV MSSQLODBC13=msodbcsql
RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo \
 && yum -y install unixODBC unixODBC-devel \
 && ACCEPT_EULA=Y yum -y install $MSSQLODBC13 \
 && yum clean all \
 && python3 -m pip install virtualenv \
 && mkdir -p /opt/venv /var/log/webapp/ /var/run/webapp/ \
 && virtualenv /opt/venv \
 && source /opt/venv/bin/activate \
 && python -m pip install gunicorn django-mssql-backend \
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
