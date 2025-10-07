<?php

header('Content-Type: text/plain; charset=utf-8');

$dsn = 'mysql:host=lamp-mysql.box;dbname=test';
$db = new \PDO($dsn, 'root', 'root', [
    \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
    \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
]);

echo "DB connection OK.\n";

$records = $db->query('SELECT * FROM messages ORDER BY created_at DESC')
    ->fetchAll();
print_r($records);
