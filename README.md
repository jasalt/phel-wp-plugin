Demo plugin that adds admin widget printing some content with [Phel](https://phel-lang.org/).

# Installation

1) Run (local) WordPress installation (eg. [VVV Vagrant](https://varyingvagrantvagrants.org/)).
2) Clone this repository into `wp-content/plugins/phel-wp-plugin`.
3) Install composer dependencies with `cd phel-wp-plugin && composer install`.
4) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` and open Admin Dashboard (`/wp-admin`) where this widget should be visible.

# Used workarounds
## `phel-config.php`

- XDebug's (included with VVV) infinite loop detection gives false positive on default setting and requires `ini_set('xdebug.max_nesting_level', 300);`
- Error log file path needs to be set into existing directory, set into plugin dir with `->setErrorLogFile($projectRootDir . 'error.log')`

## `phel-wp-plugin.php`

Phel currently has issue (https://github.com/phel-lang/web-skeleton/issues/4) with some deprecation messages printing in web page. This was avoided using output buffering on first `Phel::run` and discarding it's initial startup message from HTML output (should get logged to `error.log` still). May lead to some unexpected side effects.
