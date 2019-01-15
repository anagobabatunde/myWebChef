#!/bin/bash

#######################################
#######################################

# name
sname='MyChef'

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset
rs=$Color_Off

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
bold='\033[1m'
silent='-qq -o Dpkg::Use-Pty=0'
# Yep, this option is undocumented. We could pipe the output to null/zero but this is dirty work.However this doesn't work everytime.

#todo check platform?

if [ "$EUID" -ne 0 ]; then 
    echo -e "$Red$bold$sname$rs Script must be run with root permissions."; exit
else
    echo -e "$Cyan$bold$sname$rs is starting.."
fi

pkgList="wget zip"

echo -e "$Cyan$bold$sname$rs$Cyan Updating System.. $Color_Off"
apt $silent update && apt $silent upgrade

echo -e "$Cyan$bold$sname$rs Installing required packages.. $Color_Off"
for i in $pkgList; do
    if [ dpkg -l $i ]; then
        echo -e "$Yellow$bold$sname$rs $i seems to be alreaady installed! $Color_Off"
    else
        apt $silent install $i -y > /dev/zero
    fi
done

# TODO: suite 

#install wget to dowload file and zip to unzip
apt install wget zip -y

# Update packages and Upgrade system
echo -e "$Cyan \n Updating System.. $Color_Off"
apt update -y && apt upgrade -y

## Install apache2
echo -e "$Cyan \n Installing Apache2 $Color_Off"
apt install apache2 -y

echo -e "$Cyan \n Installing PHP & Requirements $Color_Off"
<<<<<<< HEAD
echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list
wget -O- https://www.dotdeb.org/dotdeb.gpg | apt-key add - apt update
=======
wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
>>>>>>> d9998f4c1733172de52a0359df7da9bd4d7eaa70
apt update -y
#if error sudo apt install ca-certificates apt-transport-https
apt install php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-curl php7.0-json php7.0-gd php7.0-mcrypt php7.0-msgpack php7.0-memcached php7.0-intl php7.0-sqlite3 php7.0-gmp php7.0-geoip php7.0-mbstring php7.0-xml php7.0-zip
echo -e "$Cyan \n Installing MySQL $Color_Off"
apt install mysql-server -y

echo -e "$Cyan \n Verifying installs$Color_Off"
apt install apache2
#install wordpress
echo "create database wordpress" >>f.sql
mysql -u root < f.sql
cd /tmp
apt install libapache2-mod-php -y
wget http://wordpress.org/latest.zip
rm -rf /var/www/* -y
unzip latest.zip -d /var/www
chmod 775 /var/www
cd /var/www
mv wordpress html

## TWEAKS and Settings
# Permissions
echo -e "$Cyan \n Permissions for /var/www $Color_Off"
chown -R www-data:www-data /var/www
echo -e "$Green \n Permissions have been set $Color_Off"

# Restart Apache
echo -e "$Cyan \n Restarting Apache $Color_Off"
service apache2 restart

#install wordpress script

