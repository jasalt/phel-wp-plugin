<?php
$projectRootDir = __DIR__ . '/';

return (new \Phel\Config\PhelConfig())
    ->setErrorLogFile($projectRootDir . 'error.log')
    ->setSrcDirs(['src']);
