<?php
session_start();
require __DIR__ . '/db.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($email && $password) {
        $stmt = $pdo->prepare("SELECT user_id, firstname, lastname, email, password_hash, role FROM [User] WHERE email = ? AND is_active = 1");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if ($user && hash('sha256', $password) === $user['password_hash']) {
            $_SESSION['user_id']   = $user['user_id'];
            $_SESSION['firstname'] = $user['firstname'];
            $_SESSION['lastname']  = $user['lastname'];
            $_SESSION['email']     = $user['email'];
            $_SESSION['role']      = $user['role'];

            if ($user['role'] === 'professional') {
                $stmt2 = $pdo->prepare("SELECT professional_id FROM Professional WHERE user_id = ?");
                $stmt2->execute([$user['user_id']]);
                $prof = $stmt2->fetch();
                if ($prof) $_SESSION['professional_id'] = $prof['professional_id'];
            }

            header("Location: /web/{$user['role']}/dashboard.php");
            exit;
        } else {
            $error = 'Invalid email or password.';
        }
    } else {
        $error = 'Please fill in all fields.';
    }
}

$users = $pdo->query("SELECT email, firstname, lastname, role FROM [User] WHERE is_active = 1 ORDER BY role, lastname")->fetchAll();
$baseUrl = '/web';
include __DIR__ . '/header.php';
?>

<div class="login-container">
  <div class="card shadow">
    <div class="card-body p-4">
      <h3 class="text-center mb-4"><i class="bi bi-tools"></i> ProServices Login</h3>

      <?php if ($error): ?>
        <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
      <?php endif; ?>

      <form method="POST">
        <div class="mb-3">
          <label class="form-label">Email</label>
          <select name="email" class="form-select" required>
            <option value="">-- Select User --</option>
            <?php foreach ($users as $u): ?>
              <option value="<?= htmlspecialchars($u['email']) ?>"
                <?= (isset($_POST['email']) && $_POST['email'] === $u['email']) ? 'selected' : '' ?>>
                <?= htmlspecialchars($u['firstname'] . ' ' . $u['lastname']) ?> (<?= $u['role'] ?>)
              </option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="mb-3">
          <label class="form-label">Password</label>
          <input type="password" name="password" class="form-control" required
                 placeholder="e.g. Password1! for user #1">
        </div>
        <button type="submit" class="btn btn-primary w-100">Login</button>
      </form>

      <div class="mt-3 text-muted text-center">
        <small>Passwords: Password1! through Password30!</small>
      </div>
    </div>
  </div>
</div>

<?php include __DIR__ . '/footer.php'; ?>
