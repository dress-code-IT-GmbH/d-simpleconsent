FROM intra/centos7_py36_base

RUN yum -y update \
 && yum -y install epel-release \
 && yum -y install logrotate \
 && yum clean all

# install web application
ENV APPHOME=/opt/simpleconsent
COPY simpleconsent $APPHOME
RUN pip3.6 install virtualenv \
 && mkdir -p /opt/venv /var/log/webapp/ /var/run/webapp/ \
 && virtualenv --python=/usr/bin/python3.6 /opt/venv \
 && source /opt/venv/bin/activate \
 && pip install -r $APPHOME/requirements.txt
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