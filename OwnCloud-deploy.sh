#!/bin/bash

### Supported OS: Debian 9


### Update System and install dependencies
apt-get update
apt-get -y install vim apache2 libapache2-mod-php7.0 unzip git certbot python-certbot-apache mariadb-server mariadb-client php-fpm php-common php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-mcrypt php-ldap php-zip php-curl

### disable  VIM Visual
cd ~
echo "set mouse-=a" > .vimrc

### DIrectory Listing off
sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/apache2/apache2.conf

###  Enable Services at startup
systemctl stop apache2.service
systemctl start apache2.service
systemctl enable apache2.service
systemctl stop mariadb.service
systemctl start mariadb.service
systemctl enable mariadb.service


### SQL Absichern
mysql_secure_installation

### SQL restart
systemctl restart mariadb.service

git clone  https://github.com/mirei83/OwnCloud-deploy
cd OwnCloud-deploy

### OwnCloud SQL Password anpassen
OWNCLOUD_SQL_PASS=`openssl rand -base64 20`

### SQL Datenbank anlegen
read -p "OwnCloud Datenbank wird angelegt. Bitte geben Sie das vorher vergebene SQL Root-Kennwort ein: " ROOT_SQL_PASS
mysql -u root --password=$ROOT_SQL_PASS < base.sql

cp owncloud.conf /etc/apache2/sites-available/

### OwnCloud installieren
mkdir tmp
cd /tmp && wget https://download.owncloud.org/community/owncloud-10.0.3.zip
unzip owncloud-10.0.3.zip
mv owncloud /var/www/html/owncloud
chown -R www-data:www-data /var/www/html/owncloud/
chmod -R 755 /var/www/html/owncloud/

cd ~ 

### Owncloud Einstellungen vornehmen
read -p "Wie ist der Domainname der Owncloud (Bsp.: cloud.example.com)? " OWNCLOUD_DOMAIN
read -p "Wie ist die Kontakt-Email der Owncloud (Bsp.: info@example.com)? " OWNCLOUD_EMAIL
sed -i -e "s/admin@example.com/$OWNCLOUD_EMAIL/g" /etc/apache2/sites-available/owncloud.conf
sed -i -e "s/example.com/$OWNCLOUD_DOMAIN/g" /etc/apache2/sites-available/owncloud.conf


### OwnCloud und Mods aktivieren
a2ensite owncloud.conf
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

systemctl restart apache2.service


### Certificat aktivieren
echo "Webroot = /var/www/html/owncloud!"
certbot --authenticator webroot --installer apache

systemctl restart apache2.service

### RenewScript erstellen ausführen
cd /root/
echo "echo #!/bin/bash" > certrenew.sh
echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"  > certrenew.sh
echo "/usr/bin/letsencrypt renew --non-interactive --email $OWNCLOUD_EMAIL --agree-tos --force-renewal && /etc/init.d/apache2 restart"  > certrenew.sh
chmod +x certrenew.sh

crontab -l > mycron
echo "30 1 * * * /root/renew.sh"  >> mycron
crontab mycron
rm mycron