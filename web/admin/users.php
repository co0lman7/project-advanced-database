<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

$searchName  = $_GET['name'] ?? '';
$searchEmail = $_GET['email'] ?? '';
$searchRole  = $_GET['role'] ?? '';

$users = [];

// sp_SafeSearchUsers
$stmt = $pdo->prepare("EXEC sp_SafeSearchUsers @SearchName=?, @SearchEmail=?, @SearchRole=?");
$stmt->execute([
    $searchName ?: null,
    $searchEmail ?: null,
    $searchRole ?: null,
]);
$users = $stmt->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-people"></i> User Management</h2>
<p class="text-muted">Stored Procedure: <code>sp_SafeSearchUsers</code> (SQL injection safe)</p>

<div class="card shadow-sm mb-4">
  <div class="card-header"><strong>Search Users</strong></div>
  <div class="card-body">
    <form method="GET" class="row g-3">
      <div class="col-md-3">
        <label class="form-label">Name</label>
        <input type="text" name="name" class="form-control" value="<?= htmlspecialchars($searchName) ?>" placeholder="Search by name...">
      </div>
      <div class="col-md-3">
        <label class="form-label">Email</label>
        <input type="text" name="email" class="form-control" value="<?= htmlspecialchars($searchEmail) ?>" placeholder="Search by email...">
      </div>
      <div class="col-md-3">
        <label class="form-label">Role</label>
        <select name="role" class="form-select">
          <option value="">All Roles</option>
          <option value="client" <?= $searchRole === 'client' ? 'selected' : '' ?>>Client</option>
          <option value="professional" <?= $searchRole === 'professional' ? 'selected' : '' ?>>Professional</option>
          <option value="admin" <?= $searchRole === 'admin' ? 'selected' : '' ?>>Admin</option>
        </select>
      </div>
      <div class="col-md-3 d-flex align-items-end">
        <button class="btn btn-primary me-2">Search</button>
        <a href="/web/admin/users.php" class="btn btn-outline-secondary">Reset</a>
      </div>
    </form>
  </div>
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Active</th><th>Created</th></tr>
  </thead>
  <tbody>
    <?php foreach ($users as $u): ?>
    <tr>
      <td><?= $u['user_id'] ?></td>
      <td><?= htmlspecialchars($u['firstname'] . ' ' . $u['lastname']) ?></td>
      <td><?= htmlspecialchars($u['email']) ?></td>
      <td><span class="badge bg-<?= $u['role'] === 'admin' ? 'danger' : ($u['role'] === 'professional' ? 'primary' : 'success') ?>"><?= $u['role'] ?></span></td>
      <td><?= $u['is_active'] ? '<i class="bi bi-check-circle text-success"></i>' : '<i class="bi bi-x-circle text-danger"></i>' ?></td>
      <td><?= substr($u['created_at'], 0, 10) ?></td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<p class="text-muted"><?= count($users) ?> user(s) found</p>

<?php include __DIR__ . '/../footer.php'; ?>
