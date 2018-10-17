#!/bin/bash

set -euo pipefail

PHP_PACKAGE=rh-php70

waitForDatabase() {
    while ! mysql -h $DATABASE_HOST -P $DATABASE_PORT -u $DATABASE_USER -p$DATABASE_PASSWORD -e "SELECT 1;" $DATABASE_NAME >/dev/null 2>&1; do
        echo "==> Waiting for database to become available..."
        sleep 2
    done
}

installDrupal() {
    echo "==> Installing Drupal..."
    # Load PHP environment for Drush
    set +u && . /opt/rh/$PHP_PACKAGE/enable && set -u
    drush site-install standard \
        --db-url="mysql://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME" \
        --account-name="adminuser" \
        --account-mail="email@domain.com" \
        --account-pass="password" \
        --site-name="Blog Title" \
        --site-mail="email@domain.com" \
        --no-interaction
}

flushDrupalCache() {
    echo "==> Flushing Drupal cache..."
    # Load PHP environment for Drush
    set +u && . /opt/rh/$PHP_PACKAGE/enable && set -u
    drush cache-rebuild
}

main() {
    # The directory where WordPress is installed
    readonly installdir='/var/www/html'

    cd $installdir

    waitForDatabase
    installDrupal
    flushDrupalCache
}

main
