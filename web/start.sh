#!/bin/bash

GIT_REPO="https://github.com/szmediathek/szmediathek.git"

if [ ! -f /var/www/html/sites/default/settings.php ] ; then

    echo "02. cloning repo"
    cd /var/www
    rm -rf html
    git clone ${GIT_REPO} html
    cd html
    git checkout ${GIT_BRANCH}
    mkdir -p sites/default/files && chmod 755 sites/default && chown -R www-data:www-data sites/default/files
    echo "03. setting database"
    mv /tmp/settings.php sites/default/settings.php
    sed -i "s/placeholder_PWD/${MYSQL_ROOT_PASSWORD}/g" sites/default/settings.php
    sed -i "s/placeholder_DB/${MYSQL_DATABASE}/g" sites/default/settings.php
    sed -i "s/placeholder_USER/${MYSQL_USER}/g" sites/default/settings.php
    sed -i "s/placeholder_HOST/${MYSQL_HOST}/g" sites/default/settings.php

    if [ "${MYSQL_HOST}" = "mysql" ]   ; then
        DATABASE_REPO="https://${GIT_USER}:${GIT_PASSWORD}@github.com/szmediathek/databases.git"
        cd /var/www/html
        git clone ${DATABASE_REPO} db
        cd db
        echo "02. unzip sql file"
        gunzip -c ${FILENAME} > /tmp/db1.sql
        cd ..
        #drush sql-drop #check when
        echo "02. import database"
        drush sql-cli < /tmp/db1.sql
        rm /tmp/db1.sql
    fi
else
    echo "02. pulling repo"
    cd /var/www/html
    git pull

    if [ "${UPDATE_DB}" = "1" ]; then
        DATABASE_REPO="https://${GIT_USER}:${GIT_PASSWORD}@github.com/szmediathek/databases.git"
        cd /var/www/html
        #todo: check folder not file
        if [ ! -d /var/www/html/db ] ; then
            git clone ${DATABASE_REPO} db
        else
            cd db
            git pull
            cd ..
        fi
        cd db
        echo "02. unzip sql file"
        gunzip -c ${FILENAME} > /tmp/db1.sql
        cd ..
        #drush sql-drop #check when
        echo "02. import database"
        drush sql-cli < /tmp/db1.sql
        rm /tmp/db1.sql
    fi
fi

if [[ "${MYSQL_HOST}" = "mysql" ]] ; then
    echo 'root:root' | chpasswd
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    mkdir /var/run/sshd && chmod 0755 /var/run/sshd
    mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
fi

if [[ "${FTP}" = "1" ]] ; then
   echo "setting up ftp"
   #sed -i "s/listen=NO/listen=YES/g"  /etc/vsftpd.conf
   #sed -i "s/#local_enable=YES/local_enable=YES/g"  /etc/vsftpd.conf
   #sed -i "s/#write_enable=YES/write_enable=YES/g"  /etc/vsftpd.conf
   #sed -i "s/#local_umask=022/local_umask=022/g"  /etc/vsftpd.conf
   #sed -i "s/#anon_upload_enable=YES/anon_upload_enable=YES/g"  /etc/vsftpd.conf
   #sed -i "s/#anon_mkdir_write_enable=YES/anon_mkdir_write_enable=YES/g"  /etc/vsftpd.conf
   #echo "local_root=/var/www/html" >> /etc/vsftpd.conf
	#echo "local_enable=YES" >> /etc/vsftpd.conf
	#echo "chroot_local_user=YES" >> /etc/vsftpd.conf
	#echo "write_enable=YES" >> /etc/vsftpd.conf
	#echo "local_umask=022" >> /etc/vsftpd.conf
	#sed -i "s/anonymous_enable=YES/anonymous_enable=NO/" /etc/vsftpd.conf
	#mkdir -p /var/run/vsftpd/empty
   	#service vsftpd restart
	USER=ion
	PASS=ionel
	if ( id ${USER} ); then
	  echo "User ${USER} already exists"
	else
	  echo "Creating user ${USER}"
	  ENC_PASS=$(perl -e 'print crypt($ARGV[0], "password")' ${PASS})
	  useradd -d /ftp/${USER} -m -p ${ENC_PASS} -u 1000 -s /bin/sh ${USER}
	fi
	chown www-data:www-data -R /var/www/html
fi

exec supervisord -n
