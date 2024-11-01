Demo plugin that adds admin widget printing some content with [Phel](https://phel-lang.org/).

![Image of WordPress 6.6.1 Admin Dashboard with this plugin installed](demo.png "WordPress 6.6.1 Admin Dashboard with this plugin installed")

# Installation

1) Run (local) WordPress installation (eg. [VVV Vagrant](https://varyingvagrantvagrants.org/)).
2) Clone this repository into `wp-content/plugins/phel-wp-plugin`.
3) Install composer dependencies with `cd phel-wp-plugin && composer install`.
4) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` and open Admin Dashboard (`/wp-admin`) where this widget should be visible.

# Notes on REPL usage
In [Phel REPL](https://phel-lang.org/documentation/repl/) (starts with `vendor/bin/phel repl`), the WordPress context can be loaded by running `(php/require_once "../../../wp-load.php")`, which provides environment close to vanilla PHP WP-CLI tool's `wp shell` command.

If developing a plugin using this skeleton project that is activated and gets loaded during WordPress initialization (eg. via `wp-load.php`), the REPL environment might be messed up at that point with utilities like `use` and `doc` becoming unavailable.

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
