<?php
$Module = array('name' => 'Shapes');

$ViewList = array();

$ViewList['comune'] = array(
    'script' => 'comune.php',
    'params' => array( 'Name' ),
    'functions' => array('comune')
);

$FunctionList = array();
$FunctionList['comune'] = array();
