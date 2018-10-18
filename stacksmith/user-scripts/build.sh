#!/bin/bash

set -euo pipefail

PHP_PACKAGE=rh-php70

installDependencies() {
    echo "==> Installing dependencies"
    # Common programs
    yum install -y git wget
    # PHP and extensions, including Apache (note that Drush requires PHP 7.x)
    yum -y install centos-release-scl.noarch
    yum -y install $PHP_PACKAGE $PHP_PACKAGE-php $PHP_PACKAGE-php-mysqlnd $PHP_PACKAGE-php-gd $PHP_PACKAGE-php-xml $PHP_PACKAGE-php-mbstring $PHP_PACKAGE-php-xmlrpc
    # MySQL client
    yum install -y mysql
    # PHP Composer: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
    echo "==> Installing Composer"
    cd /tmp
    wget -q https://getcomposer.org/installer
    # Create SHA384 checksum file check that composer-setup.php matches
    wget -q https://composer.github.io/installer.sig
    sed -i 's/$/  installer/' installer.sig
    sha384sum -c installer.sig
    scl enable $PHP_PACKAGE 'php installer --quiet'
    mv composer.phar /usr/bin/composer
}

configureApache() {
    HTTPD_ROOT='/opt/rh/httpd24/root'
    HTTPD_HTML="$HTTPD_ROOT/var/www/html"
    HTTPD_CONF="$HTTPD_ROOT/etc/httpd/conf/httpd.conf"

    echo "==> Configuring Apache"

    # Enable htaccess for Drupal
cat >>$HTTPD_CONF <<EOF
<Directory "$HTTPD_HTML">
    AllowOverride all
</Directory>
EOF

    # Link installdir to the path reserved for Apache htdocs
    mkdir -p $(dirname $installdir)
    ln -sfF $HTTPD_HTML $installdir
}

installDrupal() {
    echo "==> Installing Drupal"
    test -f $UPLOADS_DIR/drupal*.zip
    unzip -q $UPLOADS_DIR/drupal*.zip -d /tmp
    cp -R /tmp/drupal-*/. $installdir
}

installDrush() {
    echo "==> Installing Drush"
    # Load PHP environment to install Drush
    scl enable $PHP_PACKAGE "cd $installdir && composer require drush/drush"
}

installDrushLauncher() {
    echo "==> Installing Drush Launcher"
    wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar
    chmod +x drush.phar
    mv drush.phar /usr/bin/drush
}

main() {
    # The directory where Drupal is installed
    readonly installdir='/var/www/html'

    installDependencies
    configureApache
    installDrupal
    installDrush
    installDrushLauncher
}

main
