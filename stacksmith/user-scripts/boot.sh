#!/bin/bash

set -euo pipefail

PHP_PACKAGE=rh-php70

# Drupal commands require HOME to be defined
export HOME=/root

waitForDatabase() {
    while ! mysql -h $DATABASE_HOST -P $DATABASE_PORT -u $DATABASE_USER -p$DATABASE_PASSWORD -e "SELECT 1;" $DATABASE_NAME >/dev/null 2>&1; do
        echo "==> Waiting for database to become available"
        sleep 2
    done
}

installDrupal() {
    echo "==> Installing Drupal"
    # Load PHP environment for Drush
    scl enable $PHP_PACKAGE "cd $installdir && drush site-install standard \
        --db-url='mysql://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME' \
        --account-name='adminuser' \
        --account-mail='email@domain.com' \
        --account-pass='password' \
        --site-name='Blog Title' \
        --site-mail='email@domain.com' \
        --no-interaction"
    # Fix error that appears in Drupal's administration panel due to not setting trusted hosts
    cat >>$installdir/sites/default/settings.php <<EOF
\$settings['trusted_host_patterns'] = array('^.*$');
EOF
}

flushDrupalCache() {
    echo "==> Flushing Drupal cache"
    # Load PHP environment for Drush
    scl enable $PHP_PACKAGE "cd $installdir && drush cache-rebuild"
}

fixDrupalPermissions() {
    # Fix ownership of files as last step
    chown -R apache:apache $installdir/
}

main() {
    # The directory where WordPress is installed
    readonly installdir='/var/www/html'

    echo "==> Initializing Drupal"

    if [ -f $installdir/sites/default/settings.php ]; then
        echo "The site is already initialized!"
        return
    fi

    waitForDatabase
    installDrupal
    flushDrupalCache
    fixDrupalPermissions
}

main
