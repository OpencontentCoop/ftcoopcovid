<?php

if (!defined('MAX_AGE')) {
    define('MAX_AGE', 86400);
}
if (isset($_SERVER['HTTP_IF_MODIFIED_SINCE'])) {
    header($_SERVER['SERVER_PROTOCOL'] . ' 304 Not Modified');
    header('Expires: ' . gmdate('D, d M Y H:i:s', time() + MAX_AGE) . ' GMT');
    header('Cache-Control: max-age=' . MAX_AGE);
    header('Last-Modified: ' . gmdate('D, d M Y H:i:s', strtotime($_SERVER['HTTP_IF_MODIFIED_SINCE'])) . ' GMT');
    header('Pragma: ');

    echo '';
    eZExecution::cleanExit();
}

$name = $Params['Name'];

try {
    $data = ShapeHelper::instance()->getShape($name);
} catch (Exception $e) {
    $data = json_encode(['error' => $e->getMessage()]);
}

header('HTTP/1.1 200 OK');
header('Content-Type: application/json');
header('Cache-Control: public, must-revalidate, max-age=259200, s-maxage=259200');
header("Last-Modified: " . gmdate('D, d M Y H:i:s', time() - 86400) . ' GMT');
header("Expires: " . gmdate('D, d M Y H:i:s', time() + 864000) . ' GMT');
echo $data;
eZExecution::cleanExit();