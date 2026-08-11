{ pkgs, lib, config, ... }:

let
  startupMessage = ''
    printf '%s\n' ' , _                          , _     , _'
    printf '%s\n' '/|/ \\|     _ |\\    (|  |  |_//|/ \\   /|/ \\|\\        _, o'
    printf '%s\n' ' |__/|/\\  |/ |/     |  |  |   |__/    |__/|/ |  |  / | | /|/'
    printf '%s\n' ' |   |  |/|_/|_/     \\  /\\    |       |   |_/ \\/|_/\\/|/ | |_/'
    printf '%s\n' '                                                    (|'
    printf '\n'
    printf '%s\n' 'Setup completed! Login to the site at http://localhost:8080/wp-admin/'
    printf '\n'
    printf '%s\n' 'Username: admin'
    printf '%s\n' 'Password: password'
    printf '\n'
    printf '%s\n' 'Phel admin widget should be visible on the dashboard...'
  '';
in
{
  # CLI tools available in the shell and used by tasks.
  packages = [
    pkgs.wp-cli
    pkgs.phpPackages.composer
  ];

  languages.php = {
    enable = true;

    # PHP extensions required by WordPress.
    # Note: xml, mbstring, curl, dom, fileinfo, openssl, pdo are enabled by default.
    extensions = [
      "mysqli"     # MySQL database connectivity
      "pdo_mysql"  # PDO MySQL driver (used by some plugins)
      "gd"         # Image manipulation (thumbnails, image editing)
      "zip"        # Plugin/theme installation from zip files
      "exif"       # Image metadata reading
    ];

    # PHP-FPM pool configuration — manages PHP worker processes.
    fpm.pools.web = {
      settings = {
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 5;
      };
    };
  };

  # MariaDB database server.
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    # Create the WordPress database on first run.
    initialDatabases = [{ name = "wordpress"; }];

    # Create database user with access to the WordPress database.
    ensureUsers = [{
      name = "wordpress";
      password = "wordpress";
      ensurePermissions = { "wordpress.*" = "ALL PRIVILEGES"; };
    }];
  };

  # Caddy web server — serves WordPress via PHP-FPM.
  services.caddy = {
    enable = true;

    # No trailing slash: devenv 2.2.1 otherwise emits an exact `/` path matcher.
    virtualHosts."http://localhost:8080" = {
      extraConfig = ''
        root * ${config.devenv.root}/wordpress

        # WordPress permalink handling: serve static files directly;
        # only route non-file requests to the WordPress front controller.
        try_files {path} /index.php?{query}

        # Pass PHP requests to PHP-FPM.
        php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}

        # Serve static files directly.
        file_server
      '';
    };
  };

  # Download WordPress, symlink the plugin, and write wp-config.php
  # once MariaDB is ready and seeded.
  tasks."wordpress:setup" = {
    description = "Download WordPress, link the plugin, and create wp-config.php";
    after = [ "devenv:mysql:configure" ];
    cwd = config.devenv.root;
    exec = ''
      set -e

      mkdir -p wordpress
      cd wordpress

      # Download WordPress core if not already present.
      if [ ! -f wp-includes/version.php ]; then
        echo "Downloading WordPress..."
        wp core download
      else
        echo "WordPress already downloaded."
      fi

      # Symlink this plugin into wp-content/plugins.
      mkdir -p wp-content/plugins
      pluginName="$(basename "$DEVENV_ROOT")"
      pluginTarget="wp-content/plugins/$pluginName"
      if [ ! -e "$pluginTarget" ]; then
        ln -s "$DEVENV_ROOT" "$pluginTarget"
        echo "Plugin symlinked: $pluginTarget -> $DEVENV_ROOT"
      fi

      # Install plugin Composer dependencies.
      composer install --working-dir="$DEVENV_ROOT" --no-interaction 2>&1 || true

      # Create wp-config.php if not already present.
      if [ ! -f wp-config.php ]; then
        echo "Creating wp-config.php..."
        wp config create \
          --dbname=wordpress \
          --dbuser=wordpress \
          --dbpass=wordpress \
          --dbhost=127.0.0.1
        echo ""
        echo "WordPress configured! Visit http://localhost:8080/ to complete installation."
      else
        echo "wp-config.php already exists."
      fi

      # Enable useful WordPress development logging by default.
      wp config set WP_DEBUG true --raw
      wp config set WP_DEBUG_LOG true --raw
      wp config set WP_DEBUG_DISPLAY false --raw

      # Install WordPress and ensure the default development administrator exists.
      if ! wp core is-installed; then
        wp core install \
          --url=http://localhost:8080 \
          --title="Phel WP Plugin Demo Site" \
          --admin_user=admin \
          --admin_password=password \
          --admin_email=admin@example.com
      fi

      # Use pretty permalinks so WordPress receives path-based requests and
      # returns a 404 for unknown slugs instead of canonicalizing to home.
      wp rewrite structure '/%postname%/'

      if wp user get admin >/dev/null 2>&1; then
        wp user update admin \
          --user_pass=password \
          --role=administrator
      else
        wp user create admin admin@example.com \
          --user_pass=password \
          --role=administrator
      fi

      # Activate this plugin after WordPress provisioning.
      wp plugin activate "$pluginName"

      # Create the demo post once, matching custom-entrypoint.sh.
      postId="$(wp post list --name=demo-post --post_type=post --format=ids | awk 'NR == 1 { print $1 }')"
      if [ -z "$postId" ]; then
        postId="$(wp post create \
          --post_status=publish \
          --post_title="Demo post" \
          --post_name=demo-post \
          --post_content="Hello world." \
          --porcelain)"
      fi
      postContent="<!-- wp:paragraph -->
<p>Hello world. <a href=\"http://localhost:8080/wp-admin/post.php?post=$${postId}&amp;action=edit\">Login &amp; edit</a></p>
<!-- /wp:paragraph -->"
      wp post update "$postId" --post_content="$postContent" >/dev/null

      ${startupMessage}

      echo "Default administrator: admin / password"
      echo "Plugin activated: $pluginName"
    '';
  };

  # Hold Caddy until WordPress is on disk so the first request isn't a 404.
  processes.caddy.after = [ "wordpress:setup" ];

  # Show helpful instructions when entering the shell.
  enterShell = ''
    echo ""
    echo "============================================="
    echo "  WordPress Plugin Development Environment"
    echo "============================================="
    echo ""
    echo "Run: devenv up"
    echo "Then open: http://localhost:8080/"
    echo ""
    echo "Database credentials:"
    echo "  Host:     127.0.0.1"
    echo "  Database: wordpress"
    echo "  User:     wordpress"
    echo "  Password: wordpress"
    ${startupMessage}
    echo ""
  '';
}
