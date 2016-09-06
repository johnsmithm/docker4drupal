#!/bin/bash

GIT_REPO="https://github.com/szmediathek/szmediathek.git"

if [ ! -f /var/www/html/sites/default/settings.php ] ; then

    echo "02. cloning repo"
    cd /var/www
    rm -rf html
    git clone ${GIT_REPO} html
    cd html
    git checkout stage

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

    if [[ "${UPDATE_DB}" = "1" ]]; then
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

exec supervisord -n