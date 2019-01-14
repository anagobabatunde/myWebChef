#!/bin/bash

#######################################
#######################################

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

#install wget to dowload file and zip to unzip
sudo apt install wget -y
sudo apt install zip -y

# Update packages and Upgrade system
echo -e "$Cyan \n Updating System.. $Color_Off"
sudo apt-get update -y && sudo apt-get upgrade -y

## Install apache2
echo -e "$Cyan \n Installing Apache2 $Color_Off"
sudo apt-get install apache2 -y

echo -e "$Cyan \n Installing PHP & Requirements $Color_Off"
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key -y add -
echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt-get update -y
#if error sudo apt-get install ca-certificates apt-transport-https
sudo apt-get install php7.2 php7.2-cli php7.2-common php7.2-opcache php7.2-curl php7.2-mbstring php7.2-mysql php7.2-zip php7.2-xml -y

echo -e "$Cyan \n Installing MySQL $Color_Off"
sudo apt-get install mysql-server -y

echo -e "$Cyan \n Verifying installs$Color_Off"
sudo apt-get install apache2 php7.2 php7.2-cli php7.2-common php7.2-opcache php7.2-curl php7.2-mbstring php7.2-mysql php7.2-zip php7.2-xml -y

#install wordpress
echo "create database wordpress" >>f.sql
mysql -u root < f.sql
cd /tmp
sudo apt install libapache2-mod-php -y
sudo wget http://wordpress.org/latest.zip
sudo rm -rf /var/www/* -y
sudo unzip latest.zip -d /var/www
sudo chmod 775 /var/www
cd /var/www
sudo mv wordpress html

## TWEAKS and Settings
# Permissions
echo -e "$Cyan \n Permissions for /var/www $Color_Off"
sudo chown -R www-data:www-data /var/www
echo -e "$Green \n Permissions have been set $Color_Off"

# Restart Apache
echo -e "$Cyan \n Restarting Apache $Color_Off"
sudo service apache2 restart



#install wordpress script
