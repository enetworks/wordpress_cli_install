#!/bin/sh
#-------------------------------------------------------------------------------------------------------------
# Load config file.
source ./host_config.sh

#-------------------------------------------------------------------------------------------------------------
#Changes to iptables Rules.
cp -a /etc/sysconfig/iptables{,.orig}
cat << '_EOT_' > /etc/sysconfig/iptables
# Firewall configuration written by system-config-securitylevel
# Manual customization of this file is not recommended.
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED
-A INPUT -j ACCEPT -i lo
-A INPUT -j ACCEPT -p icmp --icmp-type any
#DROP for Attack
#Service
-A INPUT -j ACCEPT -m state --state NEW -p tcp --dport 80  -s 0/0
-A INPUT -j ACCEPT -m state --state NEW -p tcp --dport 22  -s 0/0
#Reject
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
_EOT_

#-------------------------------------------------------------------------------------------------------------
# Update to YUM Packages.
yum -y update
yum -y install yum-cron sudo openssh-clients
chkconfig yum-cron on

#-------------------------------------------------------------------------------------------------------------
### Install and Configure Apache.
yum -y install httpd

# Configure Security log options.
sed -i.orig /etc/httpd/conf/httpd.conf \
 -e '/^ServerTokens /s/ .*/ Prod/' \
 -e '/^DirectoryIndex /s/ .*/ index.php index.cgi index.html/' \
 -e '/^ServerSignature /s/ .*/ Off/' \
 -e '/^#NameVirtualHost /s/^#//' \
 -e '/<Directory \"\/var\/www\/html\">/,/<\/Directory>/s/AllowOverride None/AllowOverride ALL/' 

# Configure logrotation.
cat << '_EOT_' > /etc/logrotate.d/httpd
/var/log/httpd/*log /var/www/*/logs/*log {
    monthly
    rotate 6
    missingok
    notifempty
    sharedscripts
    postrotate
        /sbin/service httpd reload > /dev/null 2>/dev/null || true
    endscript
}
_EOT_

# Start Apache
chkconfig httpd on
service httpd start

#-------------------------------------------------------------------------------------------------------------
### Install and Configure MariaDB.
cat << '_EOT_' > /etc/yum.repos.d/mariadb.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos6-x86/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
enabled=1
_EOT_
yum -y install MariaDB-server MariaDB-client

# Configure my.cnf.
cp -a /etc/my.cnf{,.orig}
cat << '_EOT_' > /etc/my.cnf
[mysqld]
character-set-server=utf8
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
symbolic-links=0
log-bin
binlog-format=mixed
expire_logs_days=31
server-id=1

[mysqld_safe]
character-set-server=utf8
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[mysql]
default-character-set=utf8
_EOT_

# Start MariaDB
service mysql start
chkconfig mysql on

mysql -uroot << '_EOT_'
 DELETE FROM mysql.user WHERE User='';
 DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
 DROP DATABASE test;
 DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
 FLUSH PRIVILEGES;
_EOT_


#-------------------------------------------------------------------------------------------------------------
### Install and Configure PHP.
yum -y install epel-release
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
yum -y --enablerepo=remi,epel install php php-mysqlnd php-mbstring gd php-gd
sed -i '/date.timezone =/s/^\;//;/date.timezone =/s/=.*/= Asia\/Tokyo/' /etc/php.ini
yum -y install ImageMagick*

#-------------------------------------------------------------------------------------------------------------
### Install and Configure WP_CLI.
curl  -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp
wp --info

#-------------------------------------------------------------------------------------------------------------
# Append operation user 
useradd ${OPE_USER_NAME}
echo "${OPE_USER_PASS}"  | passwd --stdin ${OPE_USER_NAME}

# Set MariaDB password.
/usr/bin/mysqladmin -uroot password "${PWD_MYSQL}"

# Set sudoer.
echo -e "${OPE_USER_NAME}     ALL=(ALL)     NOPASSWD: ALL" >> /etc/sudoers

# Append operation user to apache group
usermod -a -G apache ${OPE_USER_NAME}

# Move host_config.sh
mv ./host_config.sh /home/${OPE_USER_NAME}/
chown ${OPE_USER_NAME}:${OPE_USER_NAME} /home/${OPE_USER_NAME}/host_config.sh

#-------------------------------------------------------------------------------------------------------------
# Remove server_init.sh
rm -f server_init.sh

#-------------------------------------------------------------------------------------------------------------
#SELINUX off
sed -i.orig '/^SELINUX=/s/=.*/=disabled/' /etc/selinux/config
reboot
