#!/bin/bash

#######################################
#######################################

# name
sname='MyChef'

export DEBIAN_FRONTEND="noninteractive"

#COLORS
# Reset
Color_Off='\033[0m'       # Text Reset
rs=$Color_Off

lPath='/var/log/mychef.log'
# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
bold='\033[1m'
ext=0
upd="apt-get -qq update"
upg="apt-get -qqy upgrade"
updg="$upd && $upg"
# Using apt-get instead of aptitude since that one doesn't have a stable cli
silent='-qq -o Dpkg::Use-Pty=0'
# Yep, this option is undocumented. We could pipe the output to null/zero but this is dirty work.However this doesn't work everytime
locH="127.0.0.1     localhost wp.mywebchef.org"

login='talamo_a'
mail='talamo_a@ikf3.com'
www='wp.mywebchef.org'
title='MyWebChef - anago_b & talamo_a'
WPPLUGINS=( wordpress-seo ewww-image-optimizer better-wp-security aceide )
WPPATH="/var/www/mychef.wp"

# Verification si on run as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "$Red$bold$sname$rs Script must be run with root permissions."; exit
else
    echo -e "$Cyan$bold$sname$rs is starting.."
fi

for interface in $(ls /sys/class/net/ | grep -v lo);
do
      if ! [[ $(cat /sys/class/net/$interface/carrier) = 1 ]]; then echo -e "$Red$bold$sname$rs No internet connection."; exit 1; fi
done

function log () {
    echo "myChef_[$(date --rfc-3339=seconds)]: $*" >> $lPath
}

function dlPkg () {
    log "I: Installing $*"
    for i in "$*"; do
        dpkg -s "$i" > /dev/null 2>&1 && {
            echo -e "$Yellow$bold$sname$rs $i seems to be alreaady installed! $Color_Off"
            log "W: Attempted to install $i but package is already on system"
        } || {
          apt-get install $i -y > /dev/null
            log "I: Installed $i"
           echo -e "$Green$bold$sname$rs $i installed."
        }
    done
}

function install () {
# En premier les pré-requis
pkgList="ca-certificates apt-transport-https wget zip curl openssl"
echo -e "$Cyan$bold$sname$rs Updating System.. $Color_Off"
$upd
echo -e "$Yellow$bold$sname$rs We're upgrading the system. This could take some time, please don't reboot.. $Color_Off"
log "I: Started system upgrade."
# This will avoid docker apt utils debconf error
dlPkg "apt-utils"
$upg > /dev/null
echo -e "$Cyan$bold$sname$rs$Cyan Update finished. Installing base packages.. $Color_Off"
dlPkg "ca-certificates apt-transport-https wget zip curl openssl"

# Ensuite les pkg
if ! grep -q "dotdeb" /etc/apt/sources.list; then
    echo -e "\ndeb http://packages.dotdeb.org jessie all\ndeb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
    wget -q https://www.dotdeb.org/dotdeb.gpg -O /tmp/.deb.gpg
    apt-key add /tmp/.deb.gpg > /dev/null
    if [ $? -ne 0 ]; then
        echo "$Red$bold$sname$rs Fatal: could not add dotdeb apt key. Please do it manually."
        log "E: dotdeb_key has returned $?"
    fi
fi
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/bin/wp
chmod +x /usr/bin/wp

echo -e "$Cyan$bold$sname$rs Installing required packages.. $Color_Off"
$upd
dlPkg "apache2 php7.0 php7.0-cli php7.0-common php7.0-opcache php7.0-curl php7.0-mbstring php7.0-mysql php7.0-zip php7.0-xml mysql-server libapache2-mod-php "
}

function wpInst () {
echo -e "$Cyan$bold$sname$rs Updating System.. $Color_Off"
$upd
service mysql start
mysql -u root -e "create database if not exists wordpress" > /dev/null 

if ! [ -f $WPPATH/wp-config.php ] ; then 
    echo -e "$Cyan$bold$sname$rs Installing wordpress.. $Color_Off"
    mkdir -p $WPPATH
    wp core download --locale="en_US" --quiet --path=$WPPATH --allow-root

    wp core config --dbname="wordpress" --dbuser="root" --path=$WPPATH --allow-root --quiet > /dev/null || { echo -e  "$Red$bold$sname$rs : There was an issue while connecting to SQL. Quitting."; log "E: SQL error on core config."; exit 1; }
    wp core install --allow-root --quiet --url=$www --title="$title" --admin_user="$login" --admin_password="$pass" --admin_email="$mail" --path=$WPPATH > /dev/null
    wp plugin install ${WPPLUGINS[@]} --activate --path=$WPPATH --quiet --allow-root > /dev/null
else
    wp core update --allow-root --quiet --path=$WPPATH
    echo -e "$Green$bold$sname$rs Wordpress has been updated!"
fi

echo -e "$Cyan$bold$sname$rs Setting permissions.. $Color_Off"
chown -R www-data:www-data $WPPATH
find $WPPATH -type f -exec chmod 644 {} +
find $WPPATH -type d -exec chmod 755 {} +

if ! grep -q "$locH" /etc/hosts ; then
    echo -e "\n$locH" >> /etc/hosts
fi

if ! [ -f /etc/apache2/sites-available/myWebChef.org.conf ] ; then
    echo -e "\n<VirtualHost *:80>\nServerName $www\nServerAlias $www\nDocumentRoot $WPPATH\nErrorLog \${APACHE_LOG_DIR}/error-wordpress.log\nCustomLog \${APACHE_LOG_DIR}/custom-wordpress.log combined\n</VirtualHost>" > /etc/apache2/sites-available/myWebChef.org.conf
fi
echo -e "$Cyan$sname$bold$rs \c"
a2ensite myWebChef.org
echo -e "\nServerName localhost" > /etc/apache2/conf-available/loc.conf
a2enconf loc > /dev/null
echo -e "$Cyan$sname$bold$rs \c"
service apache2 restart
echo -e "$Green$bold$sname$rs Script is finished, your credetials are the following:\nUser $login,\nPassword $pass,\nMail $mail,Adress $www\n"
}


# The script actaully starts here

if [ ! -f $lPath ]; then
    install
else
    echo -e "$Yellow$bold$sname$rs The script has already been executed.. $Color_Off"
    log "I: Script already executed."
    install
fi

pass=$(openssl rand -base64 14)

if [ ! -d $WPPATH ]; then
   wpInst
else 
    echo -e "$Yellow$bold$sname$rs Another wordpress instance seems to be already installed! Updating it.. $Color_Off"
   wpInst 
fi



