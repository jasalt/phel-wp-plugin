#!/usr/bin/env bash
set -Eeou pipefail

# Wrapper around original entrypoint appending extra initialization logic before
# starting the web server


### HACK: Make original entrypoint skip starting the server while running otherwise by
#         making it run a fake apache2-noop executable doing nothing

# Ref: https://github.com/docker-library/wordpress/blob/b8721d7271bf763d999285985277d61e78c584aa/latest/php8.3/apache/docker-entrypoint.sh

# TODO study "official" way to accomplish this from recent container updates
# - https://github.com/docker-library/wordpress/pull/971
# - https://github.com/docker-library/postgres/pull/1150/files

echo "echo 'Apache2 doing nothing yet...'" > /usr/local/bin/apache2-noop
chmod +x /usr/local/bin/apache2-noop

# Run the original entrypoint
/usr/local/bin/docker-entrypoint.sh apache2-noop

### END HACK


echo "Running extra tasks before starting apache..."

if [ -f "/COMPOSE_INITIALIZED" ]; then
	echo "Found /COMPOSE_INITIALIZED"
	echo "Initialization in custom-entrypoint.sh already done. Skipping."
else
	echo "Running custom-entrypoint.sh initialization"

	cd /var/www/html/wp-content/plugins/phel-wp-plugin
	composer install

	cd /var/www/html/

	echo "Waiting 10 seconds for MariaDB before installation"
	sleep 10  # TODO more elegant ways?

	echo "Setting up WP installation with demo credentials"

	wp core install --allow-root --url=localhost:8080 \
	   --title="Phel WP Plugin Demo Site" --admin_user=admin \
	   --admin_password=password --admin_email=example@example.com

	# Not necessary but added so Apache doesn't make noise on startup
	echo "ServerName localhost" >> /etc/apache2/apache2.conf

	wp plugin activate phel-wp-plugin --allow-root

	wp post create --post_status=publish --allow-root \
	   --post_title='Demo post' --post_content='
         <!-- wp:paragraph -->
           <p>Hello world.
             <a href="http://localhost:8080/wp-admin/post.php?post=4&amp;action=edit">Login &amp; edit</a>
           </p>
         <!-- /wp:paragraph -->'

	date > /COMPOSE_INITIALIZED

	echo ""
	echo " , _                          , _     , _                    "
	echo "/|/ \|     _ |\    (|  |  |_//|/ \   /|/ \|\        _, o     "
	echo " |__/|/\  |/ |/     |  |  |   |__/    |__/|/ |  |  / | | /|/|"
	echo " |   |  |/|_/|_/     \/ \/    |       |   |_/ \/|_/\/|/|/ | |_/"
	echo "                                                    (|"
	echo ""
	echo "Setup completed! Login to the site at http://localhost:8080/wp-admin/"
	echo ""
	echo "Username: admin"
	echo "Password: password"
	echo ""
	echo "Phel admin widget should be visible on the dashboard..."

fi

# Run server or given arguments like the original entrypoint
if [ $# -eq 0 ]; then
    exec apache2-foreground
else
    exec "$@"
fi
