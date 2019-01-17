#!/bin/bash
sudo apt-get purge 'php*' -y
sudo apt-get purge php* -y
dpkg -l | grep php| awk '{print $2}' |tr "\n" " "
sudo apt-get purge php.*
sudo rm -rf /etc/apache2
sudo rm -rf /etc/php
sudo rm -rf /var/lib/mysql
sudo rm etc/mysql
sudo rm -rf /usr/local/include/php
sudo apt-get purge "^php*"
sudo service apache2 stop
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get autoremove
sudo rm -rf /etc/apache2
sudo apt-get remove --purge mysql-server mysql-client mysql-common -y
sudo apt-get autoremove -y
sudo apt-get autoclean
rm -rf /etc/mysql
apt-get remove apache2
apt-get purge apache2
sudo apt autoremove
sudo apt remove apache2.*
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common
sudo apt-get autoremove
sudo rm -rf /etc/mysql
