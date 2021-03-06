FROM intra/centos7_py36_base

USER root

RUN if [ "${IPV4_ONLY}" = "1" ] ; \
       then echo "ip_resolve=4" >> /etc/yum.conf \
       && echo "IPV4 only build"; fi
RUN if [ ! -z "${HTTP_PROXY}" ] ; \
       then echo "proxy=${HTTP_PROXY}" >> /etc/yum.conf \
       && echo "building with proxy=${HTTP_PROXY}"; fi

RUN cat /etc/yum.conf

RUN yum -y remove "*sqlite*"
RUN yum -y install sqlite2 sqlite2-devel

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

# install web application into filesystem
ENV APPHOME=/opt/simpleconsent
COPY simpleconsent $APPHOME
COPY simpleconsent/example/templates/index.html /opt/html/consent_requ/
COPY simpleconsent/example/templates/res /opt/html/consent_requ/res

# install mssql for prod + pgsql for test env
WORKDIR $APPHOME
ENV MSSQLODBC13=msodbcsql
RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo \
 && yum -y install unixODBC unixODBC-devel \
 && ACCEPT_EULA=Y yum -y install $MSSQLODBC13 \
 && yum -y install postgresql-libs \
 && yum clean all \
 && python3 -m pip install virtualenv \
 && mkdir -p /opt/venv /var/log/webapp/ /var/run/webapp/ \
 && virtualenv /opt/venv \
 && source /opt/venv/bin/activate \
 && python -m pip install gunicorn django-mssql-backend \
 && python -m pip install psycopg2-binary \
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
