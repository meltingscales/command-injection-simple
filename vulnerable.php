<?php
/*
 * VULNERABLE VERSION - Command Injection Demo
 *
 * This version demonstrates a command injection vulnerability.
 * User input is directly passed to the shell without validation.
 *
 * Example exploit: 5; cat /etc/passwd
 */

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $seconds = $_POST['seconds'] ?? '';

    if (empty($seconds)) {
        echo json_encode(['error' => 'Seconds parameter is required']);
        exit;
    }

    // VULNERABLE: Direct command injection
    // User input is concatenated directly into shell command
    $command = "sleep " . $seconds;

    $start = microtime(true);
    exec($command, $output, $return_code);
    $end = microtime(true);

    $elapsed = round($end - $start, 2);

    echo json_encode([
        'success' => true,
        'requested' => $seconds,
        'elapsed' => $elapsed,
        'command' => $command,
        'output' => $output,
        'return_code' => $return_code
    ]);
} else {
    echo json_encode(['error' => 'POST method required']);
}
?>
