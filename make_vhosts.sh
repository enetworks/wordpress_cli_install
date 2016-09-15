#!/bin/sh

#-------------------------------------------------------------------------------------------------------------
# Load config file.
source ./host_config.sh

#-------------------------------------------------------------------------------------------------------------
# Make documentroot directory.
# /var/www/www.exsample.com/htdocs
# /var/www/www.exsample.com/logs
sudo mkdir -p /var/www/${VHOST_FQDN}/{htdocs,logs}
sudo chown -R ${OPE_USER_NAME}:apache /var/www/${VHOST_FQDN}/

#-------------------------------------------------------------------------------------------------------------
# Make virtual host.
cat << _EOT_ | sudo tee /etc/httpd/conf.d/${VHOST_FQDN}.conf
<VirtualHost *:80>
    DocumentRoot /var/www/${VHOST_FQDN}/htdocs
    ServerName ${VHOST_FQDN}
    ErrorLog  /var/www/${VHOST_FQDN}/logs/error_log
    CustomLog  /var/www/${VHOST_FQDN}/logs/access_log combined env=!nolog
</VirtualHost>
_EOT_

echo ${VHOST_FQDN} > /var/www/${VHOST_FQDN}/htdocs/index.html

#-------------------------------------------------------------------------------------------------------------
# Make database.
mysql -uroot -p${PWD_MYSQL} << _EOT_
 CREATE DATABASE ${DB_NAME};
 CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
 GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
 FLUSH PRIVILEGES;
_EOT_

#-------------------------------------------------------------------------------------------------------------
# Restart Apache
sudo service httpd restart

wp core download --locale=ja --path=/var/www/${VHOST_FQDN}/htdocs
wp core config --dbhost=${DB_HOST} --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PASS} --skip-check --path=/var/www/${VHOST_FQDN}/htdocs
wp core install --url=${WP_URL} --title=${WP_TITLE} --admin_user=${WP_ADMIN} --admin_password=${WP_ADMIN_PWD} --admin_email=${WP_ADMIN_MAIL} --path=/var/www/${VHOST_FQDN}/htdocs

for plugin in ${WP_INSTALL_PLUGINS[@]}
do
  wp plugin install $plugin  --activate --path=/var/www/${VHOST_FQDN}/htdocs
done

for plugin in ${WP_ACTIVATE_PLUGINS[@]}
do
  wp plugin activate $plugin  --path=/var/www/${VHOST_FQDN}/htdocs
done

wp theme install ${WP_THEME_URL} --activate --path=/var/www/${VHOST_FQDN}/htdocs