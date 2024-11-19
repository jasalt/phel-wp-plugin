Experimental WordPress plugin skeleton made with [Phel](https://phel-lang.org/). Adds admin widget, interfaces a little bit with WordPress database and outputs some html using Phel html library.

![Image of WordPress 6.6.1 Admin Dashboard with this plugin installed](demo.png "WordPress 6.6.1 Admin Dashboard with this plugin installed")

Please note that this project is in experimental state, doesn't come with any warranties and might lead to dangerous security issues if used in production without sufficient care taken.

# Installation

## Existing WordPress instance

Generally plugin can be installed as follows on a live WordPress site or on development server such as [VVV Vagrant](https://varyingvagrantvagrants.org/) or [LocalWP](https://localwp.com/):

1) Clone this repository into existing WP installation path `wp-content/plugins/phel-wp-plugin`.
2) Install Composer dependencies with `cd phel-wp-plugin && composer install`.
3) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` and open Admin Dashboard (`/wp-admin`) where this widget should be visible.

## Development container

For quick and simple local dev installation `docker-compose.yml` file is included which uses [Bitnami WordPress](https://hub.docker.com/r/bitnami/wordpress/) image. This can be especially useful also for providing re-producible bug reports.

```
git clone <repo-url> phel-wp-plugin
# sudo chmod -R 777 phel-wp-plugin  # probably required on Linux
cd phel-wp-plugin
docker compose up  # or podman-compose up
```

Following success message, access WP admin via http://localhost:8081/wp-admin with credentials user: "admin" password: "password". Try edit `src/main.phel` and see changes after page refresh etc.

Custom initialization scripts can be added to `docker-post-init-scripts` directory which get executed after container is created.

### Write permissions with volume mount

Container runs Apache web server as non-root user (UID 1001) which cannot write to the mounted volume (this folder) for installing Composer dependencies, writing Phel logs, temp files etc. and may lead to permission errors.

On a single user laptop used for developing `sudo chmod -R 777 phel-wp-plugin` is probably enough, but more narrow permission for the container user UID would be better for security on multi-user system.

# Editor support

Refer to [Phel documentation on Editor support](https://phel-lang.org/documentation/getting-started/#editor-support). Some discussion also about Emacs REPL integration  https://github.com/phel-lang/phel-lang/discussions/762.

# REPL usage
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


# Used workarounds

## `phel-config.php`

- XDebug's (included with VVV) infinite loop detection gives false positive on default setting and requires `ini_set('xdebug.max_nesting_level', 300);`
- Compatibility between with Phel and WordPress error logging facilities is work-in-progress. Currently error log file path is set into plugin dir with `->setErrorLogFile($projectRootDir . 'error.log')`, but this should be changed for production.
