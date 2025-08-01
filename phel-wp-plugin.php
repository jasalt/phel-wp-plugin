<?php
/*
Plugin Name: Phel Demo Plugin
Description: Adds admin widget printing some content with Phel
Version: 0.1
Author: Jarkko Saltiola
Author URI: https://codeberg.org/jasalt
*/

// Dismiss notice
// PHP Notice:  tempnam(): file created in the system's temporary directory
error_reporting(E_ALL & ~E_NOTICE);

use Phel\Phel;

$projectRootDir = __DIR__ . '/';
require $projectRootDir . 'vendor/autoload.php';

Phel::run($projectRootDir, 'phel-wp-plugin\main');
