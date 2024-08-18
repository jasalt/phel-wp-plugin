<?php
$projectRootDir = __DIR__ . '/';

ini_set('xdebug.max_stack_frames', 300);
ini_set('xdebug.max_nesting_level', 300);

return (new \Phel\Config\PhelConfig())
    ->setErrorLogFile($projectRootDir . 'error.log')
    ->setSrcDirs(['src']);
