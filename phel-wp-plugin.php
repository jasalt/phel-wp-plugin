<?php
/*
Plugin Name: Phel Demo Plugin
Description: Adds admin widget printing some content with Phel
Version: 0.2
Author: Jarkko Saltiola & contributors
Author URI: https://codeberg.org/jasalt
*/

use Phel\Phel;

$projectRootDir = __DIR__ . '/';
require $projectRootDir . 'vendor/autoload.php';

if (isset($PHP_SELF) && $PHP_SELF !== "./vendor/bin/phel"){
	// Initialize Phel environment in regular WP plugin context. This can be
	// nalso narrowed to only specific routes or conditions to avoid it's
	// runtime overhead where it's not needed.
	Phel::run($projectRootDir, 'phel-wp-plugin\main');
} else {
	// Avoid re-initializing Phel environment during REPL session when requiring
	// wp-load.php which initializes all plugins.
	print("Running REPL, skip running plugin Phel::run \n");
}
