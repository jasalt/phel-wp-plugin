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
	// Initialize Phel environment in regular WP plugin web request context.
	// This can be also narrowed to only specific routes or conditions to avoid
	// it's runtime overhead where it's not needed.
	Phel::run($projectRootDir, 'phel-wp-plugin\main');
} else {
	// Don't re-initialize Phel or run main namespace outside regular web request
	// context e.g. when starting REPL session or running as WP-CLI command.
}


/*
 * Register WP-CLI command 'wp phel' running Phel namespace at `src/cli.phel`
 * https://make.wordpress.org/cli/handbook/guides/commands-cookbook/
 */
WP_CLI::add_command( 'phel',
					 function ( $args ){
						 $projectRootDir = __DIR__ . '/';
						 Phel::run($projectRootDir, 'phel-wp-plugin\cli');
						 WP_CLI::success( "done!" );
					 }, ['shortdesc' => 'Runs Phel code as WP-CLI command']);
