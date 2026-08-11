<?php

use Phel\Config\PhelConfig;

ini_set('xdebug.max_stack_frames', 300);
ini_set('xdebug.max_nesting_level', 300);

return (new PhelConfig())
    ->withSrcDirs(['src'])
    ->withTestDirs(['tests'])
    ->withVendorDir('vendor')
    ->withErrorLogFile('data/error.log')
    ->withIgnoreWhenBuilding(['src/local.phel'])
    ->withNoCacheWhenBuilding([])
    ->withKeepGeneratedTempFiles(false)
    ->withTempDir(sys_get_temp_dir().'/phel')
    ->withFormatDirs(['src', 'tests']);
