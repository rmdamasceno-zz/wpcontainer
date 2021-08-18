#!/bin/bash
#
# Prepare our container for initial boot.

# Creating Variable Directory
if [[ ! -d /ENV ]]; then
    echo "=> The variable directory was not found. "
    echo "=> Creating directory ..."
	mkdir -p /ENV
fi 

# Checking variable file
if [[  -f /ENV/ENV ]]; then
	echo "=> Variable file found"
	source /ENV/ENV
fi

# Creating variables not found

#Generate PW to MySQL ROOT user 
if [[ -z "$MYSQL_ROOT_PASS" ]] || [[ -z "$PASS" ]]; then
	PASS=$(pwgen -s 12 1)
	echo "=> MySQL ROOT user password generated is $PASS"
	echo PASS="$PASS">>/ENV/ENV
else
	PASS=$MYSQL_ROOT_PASS
	echo PASS="$PASS">>/ENV/ENV
fi
#Generate User DB to WP
if [[ -z "$MYSQL_USER_NAME" ]] || [[ -z "$WP_USER" ]]; then
	WP_USER=$(pwgen -A0s 6 1)
	echo "=> MySQL WP user is $WP_USER"
	echo WP_USER="$WP_USER">>/ENV/ENV
else
	WP_USER=$MYSQL_USER_NAME
	echo WP_USER="$WP_USER">>/ENV/ENV
fi
#Generate PW to User DB to WP
if [[ -z "$MYSQL_USER_PWD" ]] || [[ -z "$WP_PWD" ]]; then
	WP_PWD=$(pwgen -s 12 1)
	echo "=> MySQL WP user password is $WP_PWD"
	echo WP_PWD="$WP_PWD">>/ENV/ENV
else
	WP_PWD=$MYSQL_USER_PWD
	echo WP_PWD="$WP_PWD">>/ENV/ENV
fi
#Generate DB to WP
if [[ -z "$MYSQL_DB_NAME" ]] || [[ -z "$WP_DB" ]]; then
	WP_DB=$(pwgen -A0s 6 1)
	echo "=> MySQL WP DB is $WP_DB"
	echo WP_DB="$WP_DB">>/ENV/ENV
else
	WP_DB=$MYSQL_DB_NAME
	echo WP_DB="$WP_DB">>/ENV/ENV
fi
#Generate WP Table Prefix
if [[ -z "$WP_TB_PREFIX" ]] || [[ -z "$WP_TBP" ]]; then
	WP_TBP=$(pwgen -A0s 4 1)
	echo "=> WP table prefix is $WP_TBP"
	echo WP_TBP="$WP_TBP">>/ENV/ENV
else
	WP_TBP=$WP_TB_PREFIX
	echo WP_TBP="$WP_TBP">>/ENV/ENV
fi
#Generate WP Debug
if [[ -z "$WP_DEBUG" ]]; then
	WP_DEBUG="false"
	echo "=> WP DEBUG is $WP_DEBUG"
	echo WP_DEBUG="$WP_DEBUG">>/ENV/ENV
else
	WP_DEBUG=$WP_DEBUG
	echo WP_DEBUG="$WP_DEBUG">>/ENV/ENV
fi



# Retrieve information from apache sites
if [[ ! -f /ENV/apache.conf ]]; then
	cp -rf /etc/apache2/sites-available/000-default.conf /ENV/apache.conf
else
	cp -rf /ENV/apache.conf /etc/apache2/sites-available/000-default.conf
fi

# Retrieve PHP settings information
if [[ ! -f /ENV/php.ini ]]; then
	cp -rf /etc/php/8.0/apache2/php.ini /ENV/php.ini
else
	cp -rf /ENV/php.ini /etc/php/8.0/apache2/php.ini
fi

export PASS="$PASS"
export WP_DB="$WP_DB"
export WP_USER="$WP_USER"
export WP_PWD="$WP_PWD"
export WP_TBP="$WP_TBP"
export WP_DEBUG="$WP_DEBUG"


# Where does our MySQL data live?
VOLUME_HOME="/var/lib/mysql"

#######################################
# Use sed to replace apache php.ini values for a given PHP version.
# Globals:
#   PHP_UPLOAD_MAX_FILESIZE
#   PHP_POST_MAX_SIZE
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 5.6, 7.3 etc.
# Returns:
#   None
#######################################
function replace_apache_php_ini_values () {
    echo "Updating for PHP $1"

    sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
        -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php/$1/apache2/php.ini

    sed -i "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/$1/apache2/php.ini

}
if [ -e /etc/php/5.6/apache2/php.ini ]; then replace_apache_php_ini_values "5.6"; fi
if [ -e /etc/php/$PHP_VERSION/apache2/php.ini ]; then replace_apache_php_ini_values $PHP_VERSION; fi

#######################################
# Use sed to replace cli php.ini values for a given PHP version.
# Globals:
#   PHP_TIMEZONE
# Arguments:
#   $1 - PHP version i.e. 5.6, 7.3 etc.
# Returns:
#   None
#######################################
function replace_cli_php_ini_values () {
    echo "Replacing CLI php.ini values"
    sed -i  "s/;date.timezone =/date.timezone = Europe\/London/g" /etc/php/$1/cli/php.ini
}
if [ -e /etc/php/5.6/cli/php.ini ]; then replace_cli_php_ini_values "5.6"; fi
if [ -e /etc/php/$PHP_VERSION/cli/php.ini ]; then replace_cli_php_ini_values $PHP_VERSION; fi

echo "Editing APACHE_RUN_GROUP environment variable"
sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=staff/" /etc/apache2/envvars

if [ -n "$APACHE_ROOT" ];then
    echo "Linking /var/www/html to the Apache root"
    rm -f /var/www/html && ln -s "/app/${APACHE_ROOT}" /var/www/html
fi

echo "Editing phpmyadmin config"
sed -i "s/cfg\['blowfish_secret'\] = ''/cfg['blowfish_secret'] = '`date | md5sum`'/" /var/www/phpmyadmin/config.inc.php

echo "Setting up MySQL directories"
mkdir -p /var/run/mysqld

# Setup user and permissions for MySQL and Apache
chmod -R 770 /var/lib/mysql
chmod -R 770 /var/run/mysqld

if [ -n "$VAGRANT_OSX_MODE" ];then
    echo "Setting up users and groups"
    usermod -u $DOCKER_USER_ID www-data
    groupmod -g $(($DOCKER_USER_GID + 10000)) $(getent group $DOCKER_USER_GID | cut -d: -f1)
    groupmod -g ${DOCKER_USER_GID} staff
else
    echo "Allowing Apache/PHP to write to the app"
    # Tweaks to give Apache/PHP write permissions to the app
    chown -R www-data:staff /var/www
    chown -R www-data:staff /app
fi

echo "Allowing Apache/PHP to write to MySQL"
chown -R www-data:staff /var/lib/mysql
chown -R www-data:staff /var/run/mysqld
chown -R www-data:staff /var/log/mysql

if [ -e /var/run/mysqld/mysqld.sock ];then
    echo "Removing MySQL socket"
    rm /var/run/mysqld/mysqld.sock
fi

echo "Editing MySQL config"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/user.*/user = www-data/" /etc/mysql/mysql.conf.d/mysqld.cnf

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."

    # Try the 'preferred' solution
    mysqld --initialize-insecure

    # IF that didn't work
    if [ $? -ne 0 ]; then
        # Fall back to the 'depreciated' solution
        mysql_install_db > /dev/null 2>&1
    fi

    echo "=> Done!"
    /create_mysql_users.sh
else
    echo "=> Using an existing volume of MySQL"
fi

echo "========================================================================"
echo "=   +DB to Wordpress is:"
echo "=      DB: $WP_DB"
echo "=      US: $WP_USER"
echo "=      PW: $WP_PWD"
echo "========================================================================"


if [[ ! -d /app/wordpress ]]; then
    echo "=> The WP was not found in \\app "
    echo "=> Installing WP ..."
	if [[ ! -f /tmp/wordpress.tar.gz ]]; then
		wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	fi
	tar xfz /tmp/wordpress.tar.gz -C /app/
    rm -rf /tmp/wordpress.tar.gz
else
    echo "=> Using an existing WP installation"
fi
if [[ ! -f /app/wordpress/wp-config.php ]]; then
	if [[ -z "$WP_AUTOCONFIG" ]] || [ ! "$WP_AUTOCONFIG" == "false" ]; then
		echo "=> WP_AUTOCONFIG => $WP_AUTOCONFIG"
		bash /install_wp.sh
	else
		echo "=> WP_AUTOCONFIG has been set to false, perform manual configuration"
	fi
else
	echo "=> The wp-config.php configuration file already exists in the /app/wordpress folder"
fi
echo "=> Enforcing permissions em /app..."
chown -R www-data:staff /app
echo "=> Done!"

echo "Starting supervisord"
exec supervisord -n

