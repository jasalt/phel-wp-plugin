<?php

use Phel\Config\PhelConfig;

ini_set('xdebug.max_stack_frames', 300);
ini_set('xdebug.max_nesting_level', 300);

return (new PhelConfig())
    ->setSrcDirs(['src'])
    ->setTestDirs(['tests'])
    ->setVendorDir('vendor')
    ->setErrorLogFile('data/error.log')
    ->setIgnoreWhenBuilding(['src/local.phel'])
    ->setNoCacheWhenBuilding([])
    ->setKeepGeneratedTempFiles(false)
    ->setFormatDirs(['src', 'tests']);
