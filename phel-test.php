<?php
/*
Plugin Name: Phel demo plugin
Description: Adds admin widget printing some content with Phel
Version: 0.1
Author: Jarkko Saltiola
Author URI: https://codeberg.org/jasalt
*/

use Phel\Phel;

$projectRootDir = __DIR__ . '/';

require $projectRootDir . 'vendor/autoload.php';

global $projectRootDir;

// HACK to avoid deprecation messages printed on page on phel startup
ob_start();
Phel::run($projectRootDir, 'phel-test\noop');
ob_end_clean();

Phel::run($projectRootDir, 'phel-test\main');
