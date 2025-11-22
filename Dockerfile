# Add tools to official WordPress image based on:
# - bookworm-slim https://hub.docker.com/_/debian
# - https://github.com/docker-library/php/blob/master/8.3/bookworm/apache/Dockerfile
# - https://github.com/docker-library/wordpress/blob/master/latest/php8.3/apache/Dockerfile

FROM docker.io/wordpress:php8.3


# General dependencies & utilities
# NOTE: vim-tiny does not support syntax highlighting

RUN apt-get update && \
	apt-get install -y less vim-tiny git rsync btop
	# && rm -rf /var/lib/apt/lists/* # clears package index to free space


# Install XDebug https://xdebug.org/docs/install#pecl

RUN pecl channel-update pecl.php.net
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug


# Install WP-CLI
# https://make.wordpress.org/cli/handbook/guides/installing/

WORKDIR /usr/local/bin

RUN curl -o wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp

RUN curl -o ~/.wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/main/utils/wp-completion.bash
RUN echo "source ~/.wp-completion.bash" >> ~/.bashrc
RUN echo "alias wp='wp --allow-root'" >> ~/.bashrc

# Install Composer
# TODO pin version or something as this breaks easily
# https://getcomposer.org/download/
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"

RUN mv composer.phar composer
RUN chmod +x composer


# Change back to original workdir
WORKDIR /var/www/html
