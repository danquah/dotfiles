#!/usr/bin/env bash
# apache runs on 8080 / 8443
# nginx runs on 9080 / 9443

# Inspired by https://echo.co/blog/os-x-1010-yosemite-local-development-environment-apache-php-and-mysql-homebrew
sudo launchctl unload /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null

# homebrew has a newer openssl. 
brew install homebrew/apache/httpd24 --with-brewed-openssl --with-mpm-event
brew install homebrew/apache/mod_fastcgi --with-homebrew-httpd24

#Include /usr/local/etc/apache2/2.4/extra/httpd-default.conf
PREFIX=$(brew --prefix)

if ! grep -q "^Include $PREFIX/etc/apache2/2.4/conf.d" $(brew --prefix)/etc/apache2/2.4/httpd.conf; then
	mkdir -p $PREFIX/etc/apache2/2.4/conf.d
	cat >> $(brew --prefix)/etc/apache2/2.4/httpd.conf <<EOF
Include $PREFIX/etc/apache2/2.4/conf.d/*.conf
EOF
fi

USERHOME=$(dscl . -read /Users/`whoami` NFSHomeDirectory | awk -F"\: " '{print $2}') 

mkdir -pv $USERHOME/Work/Sites/etc/{apache_conf,ssl}
mkdir -pv $USERHOME/Work/Sites/etc/apache_conf/sites
mkdir -pv $USERHOME/Work/Sites/logs
mkdir -pv $USERHOME/Work/Sites/default

MODFASTCGIPREFIX=$(brew --prefix mod_fastcgi) 
cat > $(brew --prefix)/etc/apache2/2.4/conf.d/ServerName.conf <<EOF
ServerName Fen.localhost
EOF

cat > $(brew --prefix)/etc/apache2/2.4/conf.d/fpm.conf <<EOF
 
# Load PHP-FPM via mod_fastcgi
LoadModule fastcgi_module    ${MODFASTCGIPREFIX}/libexec/mod_fastcgi.so

LoadModule actions_module libexec/mod_actions.so

<IfModule fastcgi_module>
  FastCgiConfig -maxClassProcesses 1 -idle-timeout 1500
 
  # Prevent accessing FastCGI alias paths directly
  <LocationMatch "^/fastcgi">
    <IfModule mod_authz_core.c>
      Require env REDIRECT_STATUS
    </IfModule>
    <IfModule !mod_authz_core.c>
      Order Deny,Allow
      Deny from All
      Allow from env=REDIRECT_STATUS
    </IfModule>
  </LocationMatch>
 
  FastCgiExternalServer /php-fpm -host 127.0.0.1:9000 -pass-header Authorization -idle-timeout 1500
  ScriptAlias /fastcgiphp /php-fpm
  Action php-fastcgi /fastcgiphp
 
  # Send PHP extensions to PHP-FPM
  AddHandler php-fastcgi .php
 
  # PHP options
  AddType text/html .php
  AddType application/x-httpd-php .php
  DirectoryIndex index.php index.html
</IfModule>
 
# Include our VirtualHosts
Include ${USERHOME}/Work/Sites/etc/apache_conf/sites/*.conf
EOF


MODFASTCGIPREFIX=$(brew --prefix mod_fastcgi) 
cat > $(brew --prefix)/etc/apache2/2.4/conf.d/ssl.conf <<EOF
LoadModule ssl_module libexec/mod_ssl.so
EOF

cat > $(brew --prefix)/etc/apache2/2.4/conf.d/vhost_alias.conf <<EOF
LoadModule vhost_alias_module libexec/mod_vhost_alias.so
EOF

cat > $USERHOME/Work/Sites/etc/apache_conf/sites/httpd-vhosts.conf <<EOF
#
# Listening ports.
#
#Listen 8080  # defined in main httpd.conf
Listen 8443
  
#
# Set up permissions for VirtualHosts in ~/Sites
#
<Directory "${USERHOME}/Work/Sites">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    <IfModule mod_authz_core.c>
        Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order allow,deny
        Allow from all
    </IfModule>
</Directory>
 
# For http://localhost in the users' Sites folder
<VirtualHost _default_:8080>
    ServerName localhost
    DocumentRoot "${USERHOME}/Work/Sites/default"
</VirtualHost>
<VirtualHost _default_:8443>
    ServerName localhost
    Include "${USERHOME}/Work/Sites/etc/apache_conf/ssl-shared-cert.inc"
    DocumentRoot "${USERHOME}/Work/Sites"
</VirtualHost>
 
#
# VirtualHosts
#
 
## Manual VirtualHost template for HTTP and HTTPS
#<VirtualHost *:8080>
#  ServerName project.dev
#  CustomLog "${USERHOME}/Work/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Work/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Work/Sites/project.dev"
#</VirtualHost>
#<VirtualHost *:8443>
#  ServerName project.dev
#  Include "${USERHOME}/Work/Sites/etc/apache_conf/ssl-shared-cert.inc"
#  CustomLog "${USERHOME}/Work/Sites/logs/project.dev-access_log" combined
#  ErrorLog "${USERHOME}/Work/Sites/logs/project.dev-error_log"
#  DocumentRoot "${USERHOME}/Work/Sites/project.dev"
#</VirtualHost>
 
#
# Automatic VirtualHosts
#
# A directory at ${USERHOME}/Work/Sites/webroot can be accessed at http://webroot.dev
# In Drupal, uncomment the line with: RewriteBase /
#
 
# This log format will display the per-virtual-host as the first field followed by a typical log line
LogFormat "%V %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combinedmassvhost
 
# Auto-VirtualHosts with .localhost
<VirtualHost *:8080>
  ServerName dotlocalhost
  ServerAlias *.localhost
 
  CustomLog "${USERHOME}/Work/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Work/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Work/Sites/%-2+
</VirtualHost>
<VirtualHost *:8443>
  ServerName dotlocalhost
  ServerAlias *.localhost
  Include "${USERHOME}/Work/Sites/etc/apache_conf/ssl-shared-cert.inc"
 
  CustomLog "${USERHOME}/Work/Sites/logs/dev-access_log" combinedmassvhost
  ErrorLog "${USERHOME}/Work/Sites/logs/dev-error_log"
 
  VirtualDocumentRoot ${USERHOME}/Work/Sites/%-2+
</VirtualHost>
EOF

cat > ~/Work/Sites/etc/apache_conf/ssl-shared-cert.inc <<EOF
SSLEngine On
SSLProtocol all -SSLv2 -SSLv3
SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
SSLCertificateFile "${USERHOME}/Work/Sites/etc/ssl/selfsigned.crt"
SSLCertificateKeyFile "${USERHOME}/Work/Sites/etc/ssl/private.key"
EOF

#TODO: Sign https://help.github.com/enterprise/11.10.340/admin/articles/using-self-signed-ssl-certificates/
# TODO: Autogenerate and sign
if [ ! -f ~/Work/Sites/etc/ssl/private.key ]; then
	openssl req \
       -new \
       -newkey rsa:2048 \
       -days 3650 \
       -nodes \
       -x509 \
       -subj "/C=US/ST=State/L=City/O=Organization/OU=$(whoami)/CN=*.localhost" \
       -keyout ~/Work/Sites/etc/ssl/private.key \
       -out ~/Work/Sites/etc/ssl/selfsigned.crt
fi

# Map port 80 -> 8080 and 443 -> 8443
sudo bash -c 'export TAB=$'"'"'\t'"'"'
cat > /Library/LaunchDaemons/dk.danquah.httpdfwd.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${TAB}<key>Label</key>
${TAB}<string>dk.danquah.httpdfwd</string>
${TAB}<key>ProgramArguments</key>
${TAB}<array>
${TAB}${TAB}<string>sh</string>
${TAB}${TAB}<string>-c</string>
${TAB}${TAB}<string>echo "rdr pass proto tcp from any to 127.0.0.1 port {80,8080} -> 127.0.0.1 port 8080" | pfctl -a "com.apple/260.HttpFwdFirewall" -Ef - &amp;&amp; echo "rdr pass proto tcp from any to 127.0.0.1 port {443,8443} -> 127.0.0.1 port 8443" | pfctl -a "com.apple/261.HttpFwdFirewall" -Ef - &amp;&amp; sysctl -w net.inet.ip.forwarding=1</string>
${TAB}</array>
${TAB}<key>RunAtLoad</key>
${TAB}<true/>
${TAB}<key>UserName</key>
${TAB}<string>root</string>
</dict>
</plist>
EOF'

# php
brew install homebrew/php/php56
brew install php56-opcache
mkdir -p /usr/local/etc/php/5.6/conf.d
cp conf/xxx-custom-php.ini /usr/local/etc/php/5.6/conf.d/
sed -i "s=%USERHOME%=$USERHOME=g" /usr/local/etc/php/5.6/conf.d/xxx-custom-php.ini

# Fix https://github.com/Homebrew/homebrew-php/issues/1039#issuecomment-41307694
chmod -R ug+w $(brew --prefix php56)/lib/php

	
# nginx
# Slightly inspired by http://blog.frd.mn/install-nginx-php-fpm-mysql-and-phpmyadmin-on-os-x-mavericks-using-homebrew/
brew install nginx
mkdir -pv $USERHOME/Work/Sites/etc/nginx_conf/{sites,conf.d}

# Get custom config in place.
cp conf/nginx.conf /usr/local/etc/nginx/nginx.conf
sed -i "s=%USERHOME%=$USERHOME=g" /usr/local/etc/nginx/nginx.conf

# Setup launch agent
if [ ! -f ~/Library/LaunchAgents/homebrew.mxcl.nginx.plist ]; then
	ln -sfv /usr/local/opt/nginx/homebrew.mxcl.nginx.plist ~/Library/LaunchAgents/
	# Launch it now (run as local user).
	launchctl load ~/Library/LaunchAgents/homebrew.mxcl.nginx.plist
fi





