{
  pkgs,
  lib,
  config,
  ...
}:

let
  wordpressRoot = "${config.env.DEVENV_STATE}/wordpress";
in
{
  # https://devenv.sh/packages/
  packages = [
    pkgs.coreutils
    pkgs.mariadb
    pkgs.wordpress
    pkgs.wp-cli
    pkgs.phpPackages.composer
  ];

  # https://devenv.sh/languages/
  languages = {
    php.enable = true;
    php.extensions = [
      "curl"
      "dom"
      "exif"
      "fileinfo"
      "gd"
      "mbstring"
      "mysqli"
      "openssl"
      "pdo"
      "pdo_mysql"
      "xml"
      "zip"
    ];
  };

  # Keep the database and WordPress installation in devenv state, not in the plugin repository.
  env = {
    WP_DB_NAME = "wordpress";
    WP_DB_USER = "wordpress";
    WP_DB_PASSWORD = "wordpress";
    WP_DB_HOST = "127.0.0.1:3307";
    WP_URL = "http://127.0.0.1:8080";
  };

  # https://devenv.sh/services/
  services = {
    mysql.enable = true;
    mysql.initialDatabases = [
      { name = "wordpress"; }
    ];
    mysql.ensureUsers = [
      {
        name = "wordpress";
        host = "127.0.0.1";
        password = "wordpress";
        ensurePermissions = {
          "wordpress.*" = "ALL PRIVILEGES";
        };
      }
    ];
    mysql.settings = {
      "bind-address" = "127.0.0.1";
      port = 3307;
    };
  };

  # https://devenv.sh/processes/
  # The bootstrap waits for MySQL, copies immutable WordPress core into devenv state,
  # and symlinks this repository into wp-content/plugins before serving the site.
  processes = {
    wordpress.exec = ''
      set -eu

      wordpressRoot="${wordpressRoot}"
      pluginSource="${config.env.DEVENV_ROOT}"
      composer install --working-dir="$pluginSource"
      coreSource="${pkgs.wordpress}/share/wordpress"

      if [ ! -d "$coreSource" ]; then
        coreSource="${pkgs.wordpress}"
      fi

      mkdir -p "$wordpressRoot"
      if [ ! -f "$wordpressRoot/wp-includes/version.php" ]; then
        rm -rf "$wordpressRoot"
        mkdir -p "$wordpressRoot"
        cp -R --no-preserve=mode,ownership "$coreSource"/. "$wordpressRoot"/
      fi

      mkdir -p "$wordpressRoot/wp-content/plugins"
      pluginName="$(basename "$pluginSource")"
      pluginTarget="$wordpressRoot/wp-content/plugins/$pluginName"
      rm -rf "$pluginTarget"
      ln -s "$pluginSource" "$pluginTarget"

      cat > "$wordpressRoot/router.php" <<'PHP_ROUTER'
      <?php
      $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
      $file = __DIR__ . $path;
      if ($path !== '/' && is_file($file)) {
          return false;
      }
      require __DIR__ . '/index.php';
      PHP_ROUTER

      until mysqladmin \
        --protocol=tcp \
        --host=127.0.0.1 \
        --port=3307 \
        --user="$WP_DB_USER" \
        --password="$WP_DB_PASSWORD" \
        ping >/dev/null 2>&1; do
        sleep 1
      done

      if [ ! -f "$wordpressRoot/wp-config.php" ]; then
        wp config create \
          --path="$wordpressRoot" \
          --dbname="$WP_DB_NAME" \
          --dbuser="$WP_DB_USER" \
          --dbpass="$WP_DB_PASSWORD" \
          --dbhost="$WP_DB_HOST" \
          --skip-check
      fi

      if ! wp core is-installed --path="$wordpressRoot" >/dev/null 2>&1; then
        wp core install \
          --path="$wordpressRoot" \
          --url="$WP_URL" \
          --title="WordPress Plugin Development" \
          --admin_user="admin" \
          --admin_password="admin" \
          --admin_email="admin@example.test" \
          --skip-email
      fi

      echo "WordPress: $WP_URL"
      echo "Plugin:    $pluginName"
      echo "Admin:     admin / admin"
      exec php -S 127.0.0.1:8080 -t "$wordpressRoot" "$wordpressRoot/router.php"
    '';
  };

  enterShell = ''
    echo "WordPress plugin environment ready. Run: devenv up"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
