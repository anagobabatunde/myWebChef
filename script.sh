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
lPathUp='/var/log/mychef.updates.log'
# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
bold='\033[1m'
upd="apt-get -qq update"
upg="apt-get -qqy upgrade"
updg="$upd && $upg"
# Using apt-get instead of aptitude since that one doesn't have a stable cli
silent='-qq -o Dpkg::Use-Pty=0'
# Yep, this option is undocumented. We could pipe the output to null/zero but this is dirty work.However this doesn't work everytime
login='myweb'
mail='myweb@ikf3.com'
www='wp.mywebchef.org'
title='MyWebChef'

WPPLUGINS=( wordpress-seo ewww-image-optimizer better-wp-security aceide )
WPPATH=/var/www/mychef.wp

# Verification si on run as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "$Red$bold$sname$rs Script must be run with root permissions."; exit
else
    echo -e "$Cyan$bold$sname$rs is starting.."
fi

# Function dl pkg
function dlPkg () {
        dpkg -s "$1" > /dev/null 2>&1 && {
            echo -e "$Yellow$bold$sname$rs $1 seems to be alreaady installed! $Color_Off"
        } || {
          apt-get install $1 -y >> $lPath
            echo -e "$Green$bold$sname$rs $1 installed."
        }
}

function install () {
# En premier les pré-requis
pkgList="ca-certificates apt-transport-https wget zip curl openssl"
echo -e "$Cyan$bold$sname$rs Updating System.. $Color_Off"
$upd
# This will avoid docker apt utils debconf error
echo -e
echo -e "$Yellow$bold$sname$rs We're updating the system. This could take some time, please don't reboot.. $Color_Off"
apt-get -qqy install apt-utils >> $lPath
$upg >> $lPath
echo -e "$Cyan$bold$sname$rs$Cyan Update finished. Installing base packages.. $Color_Off"
for i in $pkgList; do
    dlPkg $i
done


# Ensuite les pkg
echo -e "\ndeb http://packages.dotdeb.org jessie all\ndeb-src http://packages.dotdeb.org jessie all\n" >> /etc/apt/sources.list
wget -q https://www.dotdeb.org/dotdeb.gpg -O /tmp/.deb.gpg
apt-key add /tmp/.deb.gpg
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/bin/wp
chmod +x /usr/bin/wp

$upd

echo -e "$Cyan$bold$sname$rs Installing required packages.. $Color_Off"
pkgList="apache2 php7.0 php7.0-cli php7.0-common php7.0-opcache php7.0-curl php7.0-mbstring php7.0-mysql php7.0-zip php7.0-xml mysql-server libapache2-mod-php "
for i in $pkgList; do
    dlPkg $i
done

}

function wpInst () {

# Update packages and Upgrade system
echo -e "$Cyan \n Updating System.. $Color_Off"
$upd

echo -e "$Cyan$bold$sname$rs Installing wordpress.. $Color_Off"
mkdir -p /var/www/mychef.wp
rm -rf /var/www/html/index.html

service mysql start

wp core download --locale="en_US" --quiet --path=$WPPATH --allow-root
mysql -u root -e "create database wordpress" 
wp core config --dbname="wordpress" --dbuser="root" --path=$WPPATH --allow-root --quiet || {
  echo -e  "$Red$bold$sname$rs : There was an issue while connecting to SQL. Quitting."; exit 1;
  }

wp core install --allow-root --quiet --url=$www --title="$title" --admin_user="$login" --admin_password="$pass" --admin_email="$mail" --path=$WPPATH

wp plugin install ${WPPLUGINS[@]} --activate --path=$WPPATH --allow-root
echo -e "$Cyan$bold$sname$rs Setting permissions.. $Color_Off"
chown -R www-data:www-data $WPPATH
find $WPPATH -type f -exec chmod 644 {} +
find $WPPATH -type d -exec chmod 755 {} +

sed -i "s/127.0.0.1     localhost/127.0.0.1     localhost wp.mywebchef.org/g" >> /etc/hosts
echo -e "\n<VirtualHost *:80>\nServerName $www\nServerAlias $www\nDocumentRoot $WPPATH\nErrorLog \${APACHE_LOG_DIR}/error-wordpress.log\nCustomLog \${APACHE_LOG_DIR}/custom-wordpress.log combined\n</VirtualHost>" > /etc/apache2/sites-available/myWebChef.org.conf
a2ensite myWebChef.org

echo -e "\nServerName localhost" > /etc/apache2/conf-available/loc.conf
a2enconf loc

service apache2 restart
}

# The script actaully starts here

if [ ! -f $lPath ]; then
    install
else
    echo -e "$Yellow$bold$sname$rs The script has already been executed.. $Color_Off"
    install
fi

pass=$(openssl rand -base64 14)

if [ ! -d $WPPATH ]; then
   wpInst
else 
    echo -e "$Yellow$bold$sname$rs Another wordpress instance seems to be already installed! Switching directory.. $Color_Off"
    # TODO : Dir switch
   wpInst 
   echo -e "$Green$bold$sname$rs Script is finished, your credetials are the following:\nUser $user,\nPassword $pass,\nMail $mail,Adress $www\n"
fi


exit
#install wordpress
echo -e "$Cyan$bold$sname$rs Installing wordpress.. $Color_Off"
mysql -u root -p="\n" --execute="create database wordpress" 
wget -q http://wordpress.org/latest.zip -o /tmp/wp.zip
rm -rf /var/www/* -y
unzip /tmp/wp.zip -d /var/www
chmod 775 /var/www
mv /var/www/wordpress /var/www/html

## TWEAKS and Settings
# Permissions
echo -e "$Cyan \n Permissions for /var/www $Color_Off"
chown -R www-data:www-data /var/www
echo -e "$Green \n Permissions have been set $Color_Off"

# Restart Apache
echo -e "$Cyan \n Restarting Apache $Color_Off"
service apache2 restart

#install wordpress script

