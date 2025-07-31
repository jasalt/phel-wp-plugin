# Add tools to official WordPress image based on:
# - bookworm-slim https://hub.docker.com/_/debian
# - https://github.com/docker-library/php/blob/master/8.3/bookworm/apache/Dockerfile
# - https://github.com/docker-library/wordpress/blob/master/latest/php8.3/apache/Dockerfile

FROM wordpress:latest


# General dependencies & utilities
# NOTE: vim-tiny does not support syntax highlighting

RUN apt-get update && \
	apt-get install -y less vim-tiny
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
# https://getcomposer.org/download/
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
RUN php composer-setup.php --quiet
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar composer
RUN chmod +x composer


# Change back to original workdir
WORKDIR /var/www/html
