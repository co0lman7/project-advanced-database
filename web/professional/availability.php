<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'professional') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$profId = $_SESSION['professional_id'] ?? 0;
$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $date = $_POST['date'] ?? '';
    $startTime = $_POST['start_time'] ?? '';
    $endTime = $_POST['end_time'] ?? '';
    $status = $_POST['status'] ?? 'available';

    if ($date && $startTime && $endTime) {
        try {
            $stmt = $pdo->prepare("
                INSERT INTO Availability (status, [date], start_time, end_time, professional_id)
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmt->execute([$status, $date, $startTime, $endTime, $profId]);
            $success = 'Availability slot added!';
        } catch (PDOException $e) {
            $error = 'Failed: ' . $e->getMessage();
        }
    } else {
        $error = 'Please fill in all fields.';
    }
}

$slots = $pdo->prepare("
    SELECT * FROM Availability
    WHERE professional_id = ?
    ORDER BY [date] DESC, start_time
");
$slots->execute([$profId]);
$rows = $slots->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-clock"></i> Manage Availability</h2>

<?php if ($error): ?>
  <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="card shadow-sm mb-4">
  <div class="card-header"><strong>Add Availability Slot</strong></div>
  <div class="card-body">
    <form method="POST" class="row g-3">
      <div class="col-md-3">
        <label class="form-label">Date</label>
        <input type="date" name="date" class="form-control" required min="<?= date('Y-m-d') ?>">
      </div>
      <div class="col-md-2">
        <label class="form-label">Start Time</label>
        <input type="time" name="start_time" class="form-control" required>
      </div>
      <div class="col-md-2">
        <label class="form-label">End Time</label>
        <input type="time" name="end_time" class="form-control" required>
      </div>
      <div class="col-md-3">
        <label class="form-label">Status</label>
        <select name="status" class="form-select">
          <option value="available">Available</option>
          <option value="unavailable">Unavailable</option>
        </select>
      </div>
      <div class="col-md-2 d-flex align-items-end">
        <button class="btn btn-success w-100">Add</button>
      </div>
    </form>
  </div>
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>#</th><th>Date</th><th>Start</th><th>End</th><th>Status</th></tr>
  </thead>
  <tbody>
    <?php foreach ($rows as $r): ?>
    <tr>
      <td><?= $r['availability_id'] ?></td>
      <td><?= $r['date'] ?></td>
      <td><?= substr($r['start_time'], 0, 5) ?></td>
      <td><?= substr($r['end_time'], 0, 5) ?></td>
      <td>
        <span class="badge bg-<?= $r['status'] === 'available' ? 'success' : ($r['status'] === 'booked' ? 'primary' : 'secondary') ?>">
          <?= $r['status'] ?>
        </span>
      </td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>

<?php include __DIR__ . '/../footer.php'; ?>
