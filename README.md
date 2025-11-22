WordPress plugin skeleton made with [Phel](https://phel-lang.org/), a functional language inspired by Clojure and Janet that transpiles to PHP.

Demonstrates a basic admin widget interfacing with the database rendered using [hiccup](https://github.com/weavejester/hiccup) style [Phel HTML library](https://phel-lang.org/documentation/html-rendering/).

![Image of WordPress 6.6.1 Admin Dashboard with this plugin installed](demo.png "WordPress 6.6.1 Admin Dashboard with this plugin installed")

See also [wp.phel](https://github.com/jasalt/phel-junkshed/blob/master/wp.phel) for some wrapper functions over WP API's and [woocommerce-memberships-migrator](https://github.com/jasalt/woocommerce-memberships-migrator) as a example project (a WP-CLI utility).

# Installation

Phel requires minimum PHP version 8.3 and Composer for installing it, refer to [Phel quick start](https://phel-lang.org/documentation/getting-started/).

## Existing WordPress instance

1) Clone this repository into existing WP installation path `wp-content/plugins/phel-wp-plugin`.
2) Install Composer dependencies with `cd phel-wp-plugin && composer install`.
3) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` 

The widget should be visible on admin dashboard. Try editing `src/main.phel` and see changes after page refresh etc.

## Container

For Podman (or Docker) users, a pre-configured `docker-compose.yml` is included. The `Dockerfile` is based on official WordPress image adding Composer, WP-CLI, XDebug and some other tools to it and `custom-entrypoint.sh` installs WP and the plugin on first run.

```
git clone git@github.com:jasalt/phel-wp-plugin.git
cd phel-wp-plugin
podman compose up  # or docker compose up
```

Following success message, access WP admin via http://localhost:8080/wp-admin with credentials user: "admin" password: "password".

While `podman` is supported primarily, replacing it with `docker` in command examples should work also.

Additionally you can run Phel command line commands, including REPL eg. the following way:

```
podman compose exec -w /var/www/html/wp-content/plugins/phel-wp-plugin wp bash
./vendor/bin/phel --help
./vendor/bin/phel --version
./vendor/bin/phel repl
(php/require_once "/var/www/html/wp-load.php")
(php/get_bloginfo "name")
```

Note that to include your own namespaces declared in the plugin directory with `require`, the shell working directory should be set to plugin root directory before starting REPL.

# REPL usage
[Phel REPL](https://phel-lang.org/documentation/repl/) starts with `vendor/bin/phel repl` command. Quick way to connect to into running development container:
```
podman compose exec -w /var/www/html/wp-content/plugins/phel-wp-plugin wp vendor/bin/phel repl
```
Interfacing with the REPL works mostly as expected, examples:
```
(php/require_once "../../../wp-load.php")  # instantiate WordPress
(get php/$GLOBALS "wpdb")                  # refer to wpdb for database operations

(require phel\html :refer [html])          # load Phel core libraries
(require phel-wp-plugin\my-other-ns :as my-other-ns)  # load a Phel source file from src/
(use \Laminas\XmlRpc\Client)               # load installed Composer PHP libraries
```

### Instantiating WordPress with `wp-load.php` in REPL

WordPress runs `wp-load.php` in beginning of each HTTP request instantiating WP Core and user plugin code, after which regular WP PHP API functions including the [plugin API](https://developer.wordpress.org/reference/) will be available.

On a REPL session it needs to be manually loaded with `(php/require_once "../../../wp-load.php")`. Please let us know if you know a nicer way to refer the file as relative path is prone to failure in many situations, eg. custom WordPress project file structure like [Roots.io Bedrock](https://roots.io/bedrock/), custom container volume setup or maybe even Windows.

However when running `wp-load.php` in Phel REPL the loading of Phel plugin code itself during the WordPress initialization process needs to be considered which currently has some issues.

The REPL environment may get messed up with utilities like `use` and `doc` becoming unavailable ([see issue](https://github.com/phel-lang/phel-lang/issues/766)).

To avoid this, some REPL session aware conditional loading in plugin code is required, by eg. patching `phel-wp-plugin.php` to avoid running `Phel::run` during REPL session the following way:

```
// Skip initializing Phel again during REPL session
if (isset($PHP_SELF) && $PHP_SELF !== "./vendor/bin/phel"){
	Phel::run($projectRootDir, 'phel-wp-plugin\main');
} else {
	// This else is for debugging purposes and could be removed
	print("Running REPL, skip running plugin Phel::run \n");
}
```
### Requiring code

When evaluating Phel files during interactive development session, evaluating the regular `ns` forms may need to be avoided and Phel REPL specific functions `use` and `require` should be used instead. 

Improvement ideas in workflow regarding to this are welcome. Issues regarding to general Phel REPL experience can be raised in [phel-lang](https://github.com/phel-lang/phel-lang/issues) repository.

# Editor support

Refer to [Phel documentation on Editor support](https://phel-lang.org/documentation/getting-started/#editor-support). Some discussion also about Emacs integration with Phel REPL https://github.com/phel-lang/phel-lang/discussions/762.

# Required workarounds

## `phel-config.php`

- XDebug's (included with VVV) infinite loop detection gives false positive on default setting and requires `ini_set('xdebug.max_nesting_level', 300);`
- Plugin Phel error log file path is set into plugin dir with `->setErrorLogFile($projectRootDir . 'error.log')`, but this should be changed for production.

# Packaging notes

Composer is not required if `vendor` directory is included with the plugin distribution. Note that Composer autoloader does not play very well with WP plugins out-of-box and something like [PHP-Scoper](https://github.com/humbug/php-scoper/) or [Strauss](https://github.com/BrianHenryIE/strauss) is probably required for plugin distribution (see also https://github.com/jasalt/phel-wp-plugin/issues/9).
