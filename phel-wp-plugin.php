<?php
/*
Plugin Name: Phel Demo Plugin
Description: Adds admin widget printing some content with Phel
Version: 0.1
Author: Jarkko Saltiola
Author URI: https://codeberg.org/jasalt
*/

use Phel\Phel;

$projectRootDir = __DIR__ . '/';
error_log($projectRootDir);

require $projectRootDir . 'vendor/autoload.php';

// HACK to avoid phel 0.15.1 deprecation messages printed on page on startup
ob_start();
Phel::run($projectRootDir, 'phel-wp-plugin\noop');
ob_end_clean();

Phel::run($projectRootDir, 'phel-wp-plugin\main');
