<?php
session_start();

$root = dirname(__DIR__);
$script = $root . '/scripts/auto_deploy_on_vps.sh';
$logFile = $root . '/deploy-web/deploy.log';
$lockFile = $root . '/deploy-web/deploy.pid';

if (!file_exists($script)) {
    http_response_code(500);
    echo 'Deployment script not found: ' . htmlspecialchars($script, ENT_QUOTES, 'UTF-8');
    exit;
}

if (empty($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(16));
}

$message = '';
$error = '';

$expectedPassword = getenv('H5P_WEB_DEPLOY_PASSWORD') ?: '';
if ($expectedPassword === '') {
    $passwordFile = $root . '/deploy-web/.deploy-password';
    if (is_readable($passwordFile)) {
        $expectedPassword = trim((string) file_get_contents($passwordFile));
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!hash_equals($_SESSION['csrf'], $_POST['csrf'] ?? '')) {
        $error = 'Invalid CSRF token.';
    } elseif (!empty($_POST['admin_password'])) {
        if ($expectedPassword === '') {
            $error = 'Deployment password not configured. Set H5P_WEB_DEPLOY_PASSWORD or deploy-web/.deploy-password';
        } elseif (!hash_equals($expectedPassword, (string) $_POST['admin_password'])) {
            $error = 'Invalid deployment password.';
        }
    } else {
        $error = 'Deployment password is required.';
    }

    if (!$error) {
        $dbName = trim($_POST['db_name'] ?? '');
        $dbUser = trim($_POST['db_user'] ?? '');
        $dbPass = (string) ($_POST['db_pass'] ?? '');
        $appUrl = trim($_POST['app_url'] ?? '');

        if ($dbName === '' || $dbUser === '' || $dbPass === '' || $appUrl === '') {
            $error = 'All fields are required.';
        } elseif (!preg_match('#^https?://#', $appUrl)) {
            $error = 'App URL must start with http:// or https://';
        } else {
            $command = sprintf(
                'nohup bash %s --non-interactive --domain-root %s --db-name %s --db-user %s --db-pass %s --app-url %s > %s 2>&1 & echo $!',
                escapeshellarg($script),
                escapeshellarg($root),
                escapeshellarg($dbName),
                escapeshellarg($dbUser),
                escapeshellarg($dbPass),
                escapeshellarg($appUrl),
                escapeshellarg($logFile)
            );

            $pid = trim((string) shell_exec($command));
            if ($pid !== '') {
                file_put_contents($lockFile, $pid . PHP_EOL);
                $message = 'Deployment started. Refresh this page to see log output.';
            } else {
                $error = 'Failed to start deployment process.';
            }
        }
    }
}

$running = false;
if (file_exists($lockFile)) {
    $pid = (int) trim((string) @file_get_contents($lockFile));
    if ($pid > 0 && function_exists('posix_kill')) {
        $running = @posix_kill($pid, 0);
    }
}

$logOutput = file_exists($logFile)
    ? htmlspecialchars((string) @file_get_contents($logFile), ENT_QUOTES, 'UTF-8')
    : 'No log output yet.';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Laravel H5P Web Deployer</title>
  <style>
    body{font-family:Arial,sans-serif;max-width:900px;margin:20px auto;padding:0 16px}
    input{width:100%;padding:8px;margin:6px 0 12px}
    button{padding:10px 16px;cursor:pointer}
    .ok{background:#e8f7e8;padding:10px}.err{background:#fde8e8;padding:10px}
    pre{background:#111;color:#ddd;padding:12px;overflow:auto;max-height:360px}
  </style>
</head>
<body>
  <h1>Laravel H5P One-Click Deployer</h1>
  <p>Set password via env var <code>H5P_WEB_DEPLOY_PASSWORD</code> <strong>or</strong> file <code>deploy-web/.deploy-password</code> before use.</p>

  <?php if ($message): ?><div class="ok"><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></div><?php endif; ?>
  <?php if ($error): ?><div class="err"><?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></div><?php endif; ?>

  <form method="post">
    <input type="hidden" name="csrf" value="<?= htmlspecialchars($_SESSION['csrf'], ENT_QUOTES, 'UTF-8') ?>">
    <label>Deployment Password</label>
    <input type="password" name="admin_password" required>

    <label>MySQL DB Name</label>
    <input type="text" name="db_name" required>

    <label>MySQL DB User</label>
    <input type="text" name="db_user" required>

    <label>MySQL DB Password</label>
    <input type="password" name="db_pass" required>

    <label>App URL</label>
    <input type="text" name="app_url" placeholder="https://your-domain.com" required>

    <button type="submit">Run Deployment</button>
  </form>

  <h2>Status: <?= $running ? 'Running' : 'Idle' ?></h2>
  <pre><?= $logOutput ?></pre>
</body>
</html>
