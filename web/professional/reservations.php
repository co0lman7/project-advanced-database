<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'professional') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$profId = $_SESSION['professional_id'] ?? 0;
$error = '';
$success = '';

// Handle status update - triggers trg_PreventCompletedReservationEdit
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    $resId = (int)($_POST['reservation_id'] ?? 0);
    $newStatus = $_POST['new_status'] ?? '';

    if ($resId && in_array($newStatus, ['confirmed', 'completed', 'cancelled'])) {
        try {
            $stmt = $pdo->prepare("
                UPDATE Reservation SET status = ?
                WHERE reservation_id = ? AND professional_id = ?
            ");
            $stmt->execute([$newStatus, $resId, $profId]);
            $success = "Reservation #$resId updated to '$newStatus'.";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Completed') !== false || strpos($e->getMessage(), 'completed') !== false) {
                $error = 'Completed reservations cannot be modified (trigger: trg_PreventCompletedReservationEdit).';
            } else {
                $error = 'Update failed: ' . $e->getMessage();
            }
        }
    }
}

$reservations = $pdo->prepare("
    SELECT r.reservation_id, r.[date], r.[time], r.status, r.created_at,
           s.service_name, uc.firstname + ' ' + uc.lastname AS client_name
    FROM Reservation r
    JOIN Service s ON r.service_id = s.service_id
    JOIN [User] uc ON r.user_id = uc.user_id
    WHERE r.professional_id = ?
    ORDER BY r.[date] DESC, r.[time] DESC
");
$reservations->execute([$profId]);
$rows = $reservations->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-calendar3"></i> My Reservations</h2>
<p class="text-muted">Trigger: <code>trg_PreventCompletedReservationEdit</code> blocks editing completed reservations</p>

<?php if ($error): ?>
  <div class="alert alert-danger"><i class="bi bi-exclamation-triangle"></i> <?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><i class="bi bi-check-circle"></i> <?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr>
      <th>#</th>
      <th>Service</th>
      <th>Client</th>
      <th>Date</th>
      <th>Time</th>
      <th>Status</th>
      <th>Update Status</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach ($rows as $r): ?>
    <tr>
      <td><?= $r['reservation_id'] ?></td>
      <td><?= htmlspecialchars($r['service_name']) ?></td>
      <td><?= htmlspecialchars($r['client_name']) ?></td>
      <td><?= $r['date'] ?></td>
      <td><?= substr($r['time'], 0, 5) ?></td>
      <td>
        <span class="badge bg-<?=
          $r['status'] === 'completed' ? 'success' :
          ($r['status'] === 'confirmed' ? 'primary' :
          ($r['status'] === 'pending' ? 'warning' : 'secondary')) ?>">
          <?= $r['status'] ?>
        </span>
      </td>
      <td>
        <?php if ($r['status'] !== 'cancelled'): ?>
        <form method="POST" class="d-inline">
          <input type="hidden" name="action" value="update">
          <input type="hidden" name="reservation_id" value="<?= $r['reservation_id'] ?>">
          <select name="new_status" class="form-select form-select-sm d-inline w-auto">
            <option value="confirmed" <?= $r['status'] === 'confirmed' ? 'selected' : '' ?>>Confirmed</option>
            <option value="completed" <?= $r['status'] === 'completed' ? 'selected' : '' ?>>Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
          <button class="btn btn-sm btn-outline-primary">Save</button>
        </form>
        <?php else: ?>
          <span class="text-muted">-</span>
        <?php endif; ?>
      </td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>

<?php include __DIR__ . '/../footer.php'; ?>
