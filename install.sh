#/!/bin/bash

#update system
yum -y update

#install dev tools
yum -y groupinstall "Development Tools"
yum -y groupinstall "base" 

#install needed files
yum install -y \
    epel-release \
    libxml2-devel \
    bzip2-devel \
    libmcrypt-devel \
    libicu-devel \
    libtool-ltdl-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    lua-devel \
    python-devel \
    aspell-devel \
    readline-devel \
    libcurl-devel \
    htop \
    libev-devel

mkdir sources

#install openssl 1.0.2j
cd sources/
wget https://www.openssl.org/source/openssl-1.0.2j.tar.gz
tar -zxvf openssl-1.0.2j.tar.gz
cd openssl-1.0.2j/
./config
make
make test 
make install

# install hngttp2
cd ..
wget https://github.com/tatsuhiro-t/nghttp2/releases/download/v1.3.4/nghttp2-1.3.4.tar.gz
tar -zxvf nghttp2-1.3.4.tar.gz 
cd nghttp2-1.3.4/
autoreconf -i
automake
autoconf 
export OPENSSL_CFLAGS="-I/usr/local/ssl/include/"
export OPENSSL_LIBS="-L/usr/local/ssl/lib/ -lssl -lcrypto"
./configure 
make 
make install

#install latest curl
cd ..
rpm -Uvh http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel7.noarch.rpm
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/city-fan.org.repo
yum -y --enablerepo=city-fan.org update libcurl curl

#install apr
cd ..
wget http://mirror.vorboss.net/apache//apr/apr-1.5.2.tar.gz
tar -zxvf apr-1.5.2.tar.gz 
cd apr-1.5.2/
./configure
make
make test
make install

#install apr-util
cd ..
wget http://mirror.vorboss.net/apache//apr/apr-util-1.5.4.tar.gz
tar -zxvf apr-util-1.5.4.tar.gz 
cd apr-util-1.5.4/
./configure --with-apr=/usr/local/apr/ --with-crypto --with-openssl=/usr/local/ssl/
make 
make test
make install

# install apache
cd ..
wget http://apache.mirrors.nublue.co.uk//httpd/httpd-2.4.23.tar.gz
tar -zxvf httpd-2.4.23.tar.gz 
cd httpd-2.4.23/
cp -r ../apr-1.5.2 srclib/apr
cp -r ../apr-util-1.5.4 srclib/apr-util
./configure \
   --with-ssl=/usr/local/ssl \
   --with-pcre=/usr/bin/pcre-config \
   --enable-unique-id \
   --enable-ssl \
   --enable-so \
   --with-mpm=event
   --with-included-apr
   --enable-http2

make 
make install
mkdir /usr/local/apache2/lib
ln -s /usr/local/ssl/lib/libcrypto.so.1.0.0 /usr/local/apache2/lib/
ln -s /usr/local/ssl/lib/libssl.so.1.0.0 /usr/local/apache2/lib/
ln -s /usr/local/lib/libnghttp2.so.14 /usr/local/apache2/lib/

##generate ssl
#cd ..
#openssl genrsa 2048 > server.key
#openssl req -new -key server.key > server.csr
#openssl x509 -days 3650 -req -signkey server.key < server.csr > server.crt
#mv -i server.key /usr/local/apache2/conf/ 
#mv -i server.crt /usr/local/apache2/conf/
#chmod 400 /usr/local/apache2/conf/server.key 
#chmod 400 /usr/local/apache2/conf/server.crt

## get remi repos
rpm -Uvh  http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

## install mariadb 10.0
#cat <<REPO > /etc/yum.repos.d/mariadb.repo
# MariaDB 10.0 CentOS repository list - created 2016-12-04 20:46 UTC
# http://downloads.mariadb.org/mariadb/repositories/
#[mariadb]
#name = MariaDB
#baseurl = http://yum.mariadb.org/10.0/centos7-amd64
#gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
#gpgcheck=1
#enable=1
#REPO

#yum install -y MariaDB-server MariaDB-client

# install php
yum install -y --enablerepo=remi-php70 php php-apcu php-fpm php-opcache php-cli php-common php-gd php-mbstring php-mcrypt php-pdo php-xml php-mysqlnd

## varnish
#rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.0.el7.rpm
#yum install -y varnish

## VARNISH
#cat varnish/default.vcl > /etc/varnish/default.vcl
#cat varnish/varnish.params > /etc/varnish/varnish.params

## Varnish can listen
#sed -i 's/Listen 80/Listen 8080/g' /usr/local/apache2/conf/httpd.conf
#sed -i 's/SSLProtocol all -SSLv3/SSLProtocol -All +TLSv1 +TLSv1.1 +TLSv1.2/g' /usr/local/apache2/conf/httpd.conf

## PHP
## The first pool
cat php/www.conf > /etc/php-fpm.d/www.conf

##opcache settings
cat php/opcache.ini > /etc/php.d/10-opcache.ini

##disable mod_php
mkdir /usr/local/apache2/conf.d
cat php/php.conf > /usr/local/apache2/conf.d/php.conf
echo Include conf.d/*.conf >> /usr/local/apache2/conf/httpd.conf

##disable some un-needed modules.
mkdir /usr/local/apache2/conf.modules.d
cat modules/00-base.conf > /usr/local/apache2/conf.modules.d/00-base.conf
cat modules/00-dav.conf > /usr/local/apache2/conf.modules.d/00-dav.conf
cat modules/00-lua.conf > /usr/local/apache2/conf.modules.d/00-lua.conf
cat modules/00-mpm.conf > /usr/local/apache2/conf.modules.d/00-mpm.conf
cat modules/00-proxy.conf > /usr/local/apache2/conf.modules.d/00-proxy.conf
cat modules/01-cgi.conf > /usr/local/apache2/conf.modules.d/01-cgi.conf
echo Include conf.modules.d/*.conf >> /usr/local/apache2/conf/httpd.conf

# BASIC PERFORMANCE SETTINGS
mkdir /usr/local/apache2/conf.performance.d/
cat performance/compression.conf > /usr/local/apache2/conf.performance.d/compression.conf
cat performance/content_transformation.conf > /usr/local/apache2/conf.performance.d/content_transformation.conf
cat performance/etags.conf > /usr/local/apache2/conf.performance.d/etags.conf
cat performance/expires_headers.conf > /usr/local/apache2/conf.performance.d/expires_headers.conf
cat performance/file_concatenation.conf > /usr/local/apache2/conf.performance.d/file_concatenation.conf
cat performance/filename-based_cache_busting.conf > /usr/local/apache2/conf.performance.d/filename-based_cache_busting.conf
echo Include conf.performance.d/*.conf >> /usr/local/apache2/conf/httpd.conf

# BASIC SECURITY SETTINGS
mkdir /usr/local/apache2/conf.security.d/
cat security/apache_default.conf > /usr/local/apache2/conf.security.d/apache_default.conf
echo Include conf.security.d/*.conf >> /usr/local/apache2/conf/httpd.conf

# our domain config
mkdir /usr/local/apache2/conf.sites.d
echo Include conf.sites.d/*.conf >> /usr/local/apache2/conf/httpd.conf
echo Include /usr/local/apache2/conf/extra/httpd-ssl.conf >> /usr/local/apache2/conf/httpd.conf
cat domains/80-domain.conf > /usr/local/apache2/conf.sites.d/test.conf

# fix date timezone errors
sed -i 's#;date.timezone =#date.timezone = "Europe/London"#g' /etc/php.ini

# setup apache httpd
echo pathmunge /usr/local/apache2/bin >> /etc/profile.d/httpd.sh
cat <<EOF > /etc/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/apache2/bin/apachectl -k start
ExecReload=/usr/local/apache2/bin/apachectl -k graceful
ExecStop=/usr/local/apache2/bin/apachectl -k graceful-stop
PIDFile=/usr/local/apache2/logs/httpd.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# FIREWALL
#systemctl start firewalld.service
#systemctl enable firewalld.service
#firewall-cmd --permanent --add-port=80/tcp
#firewall-cmd --permanent --add-port=8080/tcp
#firewall-cmd --permanent --add-port=22/tcp
#systemctl restart firewalld.service

# Make sue services stay on after reboot

#systemctl enable httpd.service
#systemctl enable mariadb.service
#systemctl enable php-fpm.service
#systemctl enable varnish.service

# Start all the services we use.
systemctl start php-fpm.service
#systemctl start mariadb.service
systemctl start httpd.service
#systemctl start varnish.service

echo "<?php phpinfo();?>" > /usr/local/apache2/htdocs/index.php
