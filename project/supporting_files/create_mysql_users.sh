#!/bin/bash

/usr/bin/mysqld_safe > /dev/null 2>&1 &

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done


#mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$PASS'"
#mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION"

#mysql -uroot -e " GRANT ALL PRIVILEGES ON phpmyadmin.* TO  'pma'@'localhost'"

##Generate PW to MySQL ROOT user 
#if [[ -z "$MYSQL_ROOT_PASS" ]]; then
#	PASS=$(pwgen -s 12 1)
#	echo "=> MySQL ROOT user password generated is $PASS"
#else
#	PASS=$MYSQL_ROOT_PASS
#fi
##Generate User DB to WP
#if [[ -z "$MYSQL_USER_NAME" ]]; then
#	WP_USER=$(pwgen -s 12 1)
#	echo "=> MySQL WP user is $WP_USER"
#else
#	WP_USER=$MYSQL_USER_NAME
#fi
##Generate PW to User DB to WP
#if [[ -z "$MYSQL_USER_PWD" ]]; then
#	WP_PWD=$(pwgen -s 12 1)
#	echo "=> MySQL WP user password is $WP_PWD"
#else
#	WP_PWD=$MYSQL_USER_PWD
#fi
##Generate DB to WP
#if [[ -z "$MYSQL_DB_NAME" ]]; then
#	WP_DB=$(pwgen -s 12 1)
#	echo "=> MySQL WP DB is $WP_DB"
#else
#	WP_DB=$MYSQL_DB_NAME
#fi

mysql -uroot -e "CREATE USER '$WP_USER'@'%' IDENTIFIED BY  '$WP_PWD'"
mysql -uroot -e "GRANT USAGE ON *.* TO  '$WP_USER'@'%' IDENTIFIED BY '$WP_PWD'"
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $WP_DB"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $WP_DB.* TO '$WP_USER'@'%'"
mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASS'"

#export WP_DB="$WP_DB"
#export WP_USER="$WP_USER"
#export WP_PWD="$WP_PWD"
#
#echo "=> Done!"
#
#echo "========================================================================"
#echo "DB to Wordpress is created:"
#echo "DB: $WP_DB"
#echo "US: $WP_USER"
#echo "PW: $WP_PWD"
#echo "========================================================================"

mysqladmin -uroot -p$PASS shutdown
