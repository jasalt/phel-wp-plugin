Experimental WordPress plugin skeleton made with [Phel](https://phel-lang.org/). Adds admin widget, interfaces a little bit with WordPress database and outputs some html using Phel html library.

![Image of WordPress 6.6.1 Admin Dashboard with this plugin installed](demo.png "WordPress 6.6.1 Admin Dashboard with this plugin installed")

Please note that this project is in experimental state, doesn't come with any warranties and might lead to dangerous security issues if used in production without sufficient care taken.

# Installation

Phel requires minimum PHP version 8.2 and Composer. Composer is not required if `vendor` directory is included with the plugin distribution.

## Existing WordPress instance

Generally plugin can be installed as follows on a live WordPress site or on development server such as [VVV Vagrant](https://varyingvagrantvagrants.org/) or [LocalWP](https://localwp.com/):

1) Clone this repository into existing WP installation path `wp-content/plugins/phel-wp-plugin`.
2) Install Composer dependencies with `cd phel-wp-plugin && composer install`.
3) Activate plugin on plugin management page or with `wp plugin activate phel-wp-plugin` and open Admin Dashboard (`/wp-admin`) where this widget should be visible.

## Development container

For quick and simple local dev installation `docker-compose.yml` file is included which uses [Bitnami WordPress](https://hub.docker.com/r/bitnami/wordpress/) image. This can be especially useful also for providing re-producible bug reports.

```
git clone git@github.com:jasalt/phel-wp-plugin.git
# sudo chmod -R 777 phel-wp-plugin  # probably required on Linux
cd phel-wp-plugin
docker compose up  # or podman-compose up
```

Following success message, access WP admin via http://localhost:8081/wp-admin with credentials user: "admin" password: "password". Try edit `src/main.phel` and see changes after page refresh etc.

Additionally you can run Phel command line commands, including REPL eg. the following way:

```
docker compose exec -w /opt/bitnami/wordpress/wp-content/plugins/phel-wp-plugin wordpress bash
./vendor/bin/phel --help
./vendor/bin/phel --version
./vendor/bin/phel repl
(php/require_once "/opt/bitnami/wordpress/wp-load.php")
(php/get_bloginfo "name")
```

Note that to include your own namespaces declared in the plugin directory with `require`, the shell working directory should be set to plugin root directory before starting REPL. Also with the current container setup, referring to WP Core is more reliable via absolute path.

Custom initialization scripts can be added to `docker-post-init-scripts` directory which get executed after container is created for tailored experience.

### Write permissions with volume mount

Container runs Apache web server as non-root user (UID 1001) which cannot write to the mounted volume (this folder) for installing Composer dependencies, writing Phel logs, temp files etc. and may lead to permission errors.

On a single user laptop used for developing `sudo chmod -R 777 phel-wp-plugin` is probably enough, but more narrow permission for the container user UID would be better for security on multi-user system.

### Managing container as root user

Login as root user into the container to manage packages or do other other actions default user is prohibited from doing:
```
docker compose exec -uroot wordpress bash
install_packages vim  # install vim using container's apt wrapper 
```

# REPL usage
[Phel REPL](https://phel-lang.org/documentation/repl/) starts with `vendor/bin/phel repl` command. Quick way to connect to into running development container:
```
docker compose exec -w /opt/bitnami/wordpress/wp-content/plugins/phel-wp-plugin wordpress vendor/bin/phel repl
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
