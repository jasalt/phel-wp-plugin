{ pkgs, lib, config, ... }:

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

        # WordPress permalink handling: route non-file requests to index.php.
        try_files {path} {path}/index.php /index.php?{query}

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
    echo ""
  '';
}
