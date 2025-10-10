<?php
/*
 * SAFE VERSION - Properly Secured Against Command Injection
 *
 * This version demonstrates proper input validation and secure execution.
 * Multiple layers of defense prevent command injection attacks.
 */

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $seconds = $_POST['seconds'] ?? '';

    if (empty($seconds)) {
        echo json_encode(['error' => 'Seconds parameter is required']);
        exit;
    }

    // Defense 1: Validate input is numeric
    if (!is_numeric($seconds)) {
        echo json_encode(['error' => 'Invalid input: seconds must be a number']);
        exit;
    }

    // Defense 2: Convert to integer to strip any decimal/special chars
    $seconds_int = intval($seconds);

    // Defense 3: Enforce reasonable bounds
    if ($seconds_int < 0 || $seconds_int > 30) {
        echo json_encode(['error' => 'Seconds must be between 0 and 30']);
        exit;
    }

    // Defense 4: Use escapeshellarg for additional protection
    $safe_seconds = escapeshellarg($seconds_int);

    // Safe command execution
    $command = "sleep " . $safe_seconds;

    $start = microtime(true);
    exec($command, $output, $return_code);
    $end = microtime(true);

    $elapsed = round($end - $start, 2);

    echo json_encode([
        'success' => true,
        'requested' => $seconds_int,
        'elapsed' => $elapsed,
        'command' => $command,
        'output' => $output,
        'return_code' => $return_code
    ]);
} else {
    echo json_encode(['error' => 'POST method required']);
}
?>
