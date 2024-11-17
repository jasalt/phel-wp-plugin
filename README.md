Experimental WordPress plugin skeleton made with [Phel](https://phel-lang.org/).
Adds admin widget, interfaces a little bit with WordPress database and outputs some html using Phel html library.

![Image of WordPress 6.6.1 Admin Dashboard with this plugin installed](demo.png "WordPress 6.6.1 Admin Dashboard with this plugin installed")

# Installation on existing WordPress instance

Please note that this project is in experimental state, doesn't come with any warranties and might lead to dangerous security issues if used in production without sufficient care taken.

Generally plugin can be installed as follows:

1) Clone this repository into existing WP installation path `wp-content/plugins/phel-wp-plugin`.
2) Install Composer dependencies with `cd phel-wp-plugin && composer install`.
3) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` and open Admin Dashboard (`/wp-admin`) where this widget should be visible.

Various local development environment tools can be also used, eg. [VVV Vagrant](https://varyingvagrantvagrants.org/) or [LocalWP](https://localwp.com/).

## Docker Compose setup

For quick and simple local dev installation `docker-compose.yml` file is included which uses [Bitnami WordPress](https://hub.docker.com/r/bitnami/wordpress/) image.

```
git clone <repo-url> phel-wp-plugin
# sudo chmod -R 777 phel-wp-plugin  # probably required on linux
cd phel-wp-plugin
docker compose up  # or podman-compose up
```

Following success message, access WP admin via http://localhost:8081/wp-admin with credentials user: "admin" password: "password".

Try edit `src/main.phel` and see changes after page refresh etc.

### Write permissions with volume mount

Container runs Apache web server as non-root user (UID 1001) which cannot write to the mounted volume (this folder) for installing Composer dependencies, writing Phel logs, temp files etc. and may lead to permission errors.

On a single user laptop used for developing `sudo chmod -R 777 phel-wp-plugin` is probably enough, but more narrow permission for the container user UID would be better for security on multi-user system.

# Notes on REPL usage
In [Phel REPL](https://phel-lang.org/documentation/repl/) (starts with `vendor/bin/phel repl`), the WordPress context can be loaded by running `(php/require_once "../../../wp-load.php")`.

If developing a plugin using this skeleton project that is activated and gets loaded during WordPress initialization (eg. via `wp-load.php`), the REPL environment might be messed up at that point with utilities like `use` and `doc` becoming unavailable ([see issue](https://github.com/phel-lang/phel-lang/issues/766)).

To avoid this, some REPL session aware conditional loading in plugin code is required, by eg. patching `phel-wp-plugin.php` to avoid running `Phel::run` during REPL session: 

```
// Avoid loading plugin during Phel REPL session so that REPL helpers stay available
if (isset($PHP_SELF) && $PHP_SELF !== "./vendor/bin/phel"){
	Phel::run($projectRootDir, 'phel-wp-plugin\main');
} else {
	print("Running REPL, skip running plugin Phel::run \n");
	// TODO how to load plugin phel code then?
}
```

## Emacs support
Some discussion in Emacs integration https://github.com/phel-lang/phel-lang/discussions/762.

# Used workarounds

## `phel-config.php`

- XDebug's (included with VVV) infinite loop detection gives false positive on default setting and requires `ini_set('xdebug.max_nesting_level', 300);`
- Error log file path needs to be set into existing directory, set into plugin dir with `->setErrorLogFile($projectRootDir . 'error.log')`

# Troubleshooting
## Upgrading from phel 0.15.1
Delete cache files `rm -rf data/.cache/` after `composer update`. Following should be fixed:

Deprecation warning appearing on page with 0.15.1 ([Phel repo issue](https://github.com/phel-lang/web-skeleton/issues/4)):
```
Error Unknown(4437) found! message: "Since gacela-project/gacela 1.8: `Gacela\Framework\AbstractDependencyProvider` is deprecated and will be removed in version 2.0. Use `Gacela\Framework\AbstractProvider` instead.
```

Fatal error after updating to 0.15.2 (because of cached files):
```
Uncaught TypeError: Gacela\Framework\ClassResolver\AbstractClassResolver::createInstance(): Return value must be of type object, null returned in /srv/www/wordpress-one/public_html/wp-content/pl
ugins/phel-wp-wishlist/vendor/gacela-project/gacela/src/Framework/ClassResolver/AbstractClassResolver.php:151
```
