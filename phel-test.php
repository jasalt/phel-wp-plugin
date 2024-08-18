<?php
/*
Plugin Name: Phel test plugin
Description: A brief description of my plugin.
Version: 1.0
Author: Your Name
Author URI: https://yourwebsite.com
*/

use Phel\Phel;

$projectRootDir = __DIR__ . '/';

require $projectRootDir . 'vendor/autoload.php';

/* dashboard widget */
function phel_widget() {
	global $projectRootDir;
	Phel::run($projectRootDir, 'phel-test\main');
}

// Dashboard initialisation hook
add_action('wp_dashboard_setup', function(){
	wp_add_dashboard_widget('phel-widget', 'phel content', 'phel_widget');
});
