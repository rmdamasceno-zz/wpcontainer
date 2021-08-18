FROM ubuntu:20.04
ENV REFRESHED_AT 2021-08-09

# based on mattrayner/lamp
# https://hub.docker.com/r/mattrayner/lamp

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

ENV PHPMYADMIN_VERSION=5.0.2
ENV SUPERVISOR_VERSION=4.2.0

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql && \
    groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1) && \
    groupmod -g ${BOOT2DOCKER_GID} staff

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install software-properties-common && \
  add-apt-repository -y ppa:ondrej/php && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install postfix python3-setuptools wget git apache2 php-xdebug libapache2-mod-php mysql-server php-mysql pwgen php-apcu php-gd php-xml php-mbstring zip unzip php-zip curl php-curl php-imagick && \
  apt-get -y autoremove && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install supervisor 4
RUN curl -L https://pypi.io/packages/source/s/supervisor/supervisor-${SUPERVISOR_VERSION}.tar.gz | tar xvz && \
  cd supervisor-${SUPERVISOR_VERSION}/ && \
  python3 setup.py install

# Add image configuration and scripts
ADD supporting_files/start-apache2.sh /start-apache2.sh
ADD supporting_files/start-mysqld.sh /start-mysqld.sh
ADD supporting_files/run.sh /run.sh
RUN chmod 755 /*.sh
ADD supporting_files/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supporting_files/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supporting_files/supervisord.conf /etc/supervisor/supervisord.conf
ADD supporting_files/mysqld_innodb.cnf /etc/mysql/conf.d/mysqld_innodb.cnf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql

# Add MySQL utils
ADD supporting_files/create_mysql_users.sh /create_mysql_users.sh

# Add phpmyadmin
RUN wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
RUN tar xfvz /tmp/phpmyadmin.tar.gz -C /var/www
RUN ln -s /var/www/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /var/www/phpmyadmin
RUN mv /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php
RUN rm -rf /tmp/phpmyadmin.tar.gz

# Add composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

ENV MYSQL_PASS:-$(pwgen -s 12 1)
# config to enable .htaccess
ADD supporting_files/apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN mkdir -p /app

#Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 100M
ENV PHP_POST_MAX_SIZE 100M
ENV PHP_VERSION 8.0

#Persistent Volume
RUN mkdir -p /ENV

# Add wordpress as Default APP
RUN wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
RUN tar xfvz /tmp/wordpress.tar.gz -C /app/
RUN rm -fr /var/www/html && ln -s /app/wordpress /var/www/html
ADD supporting_files/install_wp.sh /install_wp.sh

# Add CertBot to installation
RUN apt-get -y install python3 python3-venv libaugeas0 && \
  apt-get -y remove certbot && \
  python3 -m venv /opt/certbot/ && \
  /opt/certbot/bin/pip install --upgrade pip && \
  /opt/certbot/bin/pip install certbot certbot-apache && \
  ln -s /opt/certbot/bin/certbot /usr/bin/certbot  && \
  apt-get -y autoremove 

# Add volumes for the app and MySql
VOLUME  ["/var/lib/mysql", "/app" , "/ENV"]

EXPOSE 80 443
CMD ["/run.sh"]
