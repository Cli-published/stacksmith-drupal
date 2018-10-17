#!/bin/bash

set -euo pipefail

PHP_PACKAGE=rh-php70

installDependencies() {
    echo "==> Installing dependencies..."
    # Common programs
    yum install -y git wget
    # PHP and extensions, including Apache (note that Drush requires PHP 7.x)
    yum -y install centos-release-scl.noarch
    yum -y install $PHP_PACKAGE $PHP_PACKAGE-php $PHP_PACKAGE-php-mysqlnd $PHP_PACKAGE-php-gd $PHP_PACKAGE-php-xml $PHP_PACKAGE-php-mbstring $PHP_PACKAGE-php-xmlrpc
    # MySQL client
    yum install -y mysql
    # Load PHP environment to install Composer
    set +u && . /opt/rh/$PHP_PACKAGE/enable && set -u
    # PHP Composer: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
    EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
        >&2 echo 'ERROR: Invalid installer signature'
        rm composer-setup.php
        exit 1
    fi
    php composer-setup.php --quiet
    rm composer-setup.php
    mv composer.phar /usr/bin/composer
}

installDrupal() {
    # The directory where Drupal is installed
    readonly installdir='/opt/rh/httpd24/root/var/www/html'

    cd $installdir

    echo "==> Installing Drupal"
    test -f $UPLOADS_DIR/drupal*.zip
    unzip -q $UPLOADS_DIR/drupal*.zip -d /tmp
    cp -R /tmp/drupal-*/. .

    # Make installdir easily accessible by creating a symlink at /var/www/html
    mkdir /var/www
    ln -sfF $installdir /var/www/html
}

installDrush() {
    echo "==> Installing Drush"
    # Load PHP environment to install Drush
    set +u && . /opt/rh/$PHP_PACKAGE/enable && set -u
    composer require drush/drush
}

installDrushLauncher() {
    echo "==> Installing Drush Launcher"
    wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.6.0/drush.phar
    chmod +x drush.phar
    mv drush.phar /usr/bin/drush
}

main() {
    installDependencies
    installDrupal
    installDrush
    installDrushLauncher
}

main
