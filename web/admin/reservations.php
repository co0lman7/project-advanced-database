<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$error = '';
$success = '';

$startDate = $_GET['start_date'] ?? date('Y-01-01');
$endDate = $_GET['end_date'] ?? date('Y-12-31');
$filterProfId = $_GET['professional_id'] ?? '';
$filterStatus = $_GET['status'] ?? '';

// Handle payment insert - triggers trg_UpdateReservationPaymentStatus
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_payment'])) {
    $resId = (int)$_POST['reservation_id'];
    $amount = (float)$_POST['amount'];
    $method = $_POST['method'];

    try {
        $stmt = $pdo->prepare("INSERT INTO Payment (reservation_id, amount, method, payment_status) VALUES (?, ?, ?, 'paid')");
        $stmt->execute([$resId, $amount, $method]);
        $success = "Payment added for reservation #$resId. Trigger trg_UpdateReservationPaymentStatus auto-confirmed it.";
    } catch (PDOException $e) {
        $error = 'Payment failed: ' . $e->getMessage();
    }
}

// Handle reservation delete - triggers trg_LogReservationDeletion
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_reservation'])) {
    $resId = (int)$_POST['reservation_id'];
    try {
        $stmt = $pdo->prepare("DELETE FROM Payment WHERE reservation_id = ?");
        $stmt->execute([$resId]);
        $stmt = $pdo->prepare("DELETE FROM Review WHERE reservation_id = ?");
        $stmt->execute([$resId]);
        $stmt = $pdo->prepare("DELETE FROM Reservation WHERE reservation_id = ?");
        $stmt->execute([$resId]);
        $success = "Reservation #$resId deleted. Trigger trg_LogReservationDeletion logged it to ReservationAuditLog.";
    } catch (PDOException $e) {
        $error = 'Delete failed: ' . $e->getMessage();
    }
}

// sp_GetReservationsByDateRange
$stmt = $pdo->prepare("EXEC sp_GetReservationsByDateRange @StartDate=?, @EndDate=?, @ProfessionalID=?, @Status=?");
$stmt->execute([
    $startDate,
    $endDate,
    $filterProfId ?: null,
    $filterStatus ?: null,
]);
$reservations = $stmt->fetchAll();

$professionals = $pdo->query("SELECT p.professional_id, u.firstname + ' ' + u.lastname AS name FROM Professional p JOIN [User] u ON p.user_id = u.user_id ORDER BY name")->fetchAll();

// Audit log
$auditLog = $pdo->query("SELECT TOP 10 * FROM ReservationAuditLog ORDER BY DeletedAt DESC")->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-calendar3"></i> Reservations</h2>
<p class="text-muted">SP: <code>sp_GetReservationsByDateRange</code> | Triggers: <code>trg_UpdateReservationPaymentStatus</code>, <code>trg_LogReservationDeletion</code></p>

<?php if ($error): ?>
  <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="card shadow-sm mb-4">
  <div class="card-header"><strong>Filter Reservations</strong></div>
  <div class="card-body">
    <form method="GET" class="row g-3">
      <div class="col-md-2">
        <label class="form-label">Start Date</label>
        <input type="date" name="start_date" class="form-control" value="<?= htmlspecialchars($startDate) ?>">
      </div>
      <div class="col-md-2">
        <label class="form-label">End Date</label>
        <input type="date" name="end_date" class="form-control" value="<?= htmlspecialchars($endDate) ?>">
      </div>
      <div class="col-md-3">
        <label class="form-label">Professional</label>
        <select name="professional_id" class="form-select">
          <option value="">All</option>
          <?php foreach ($professionals as $p): ?>
            <option value="<?= $p['professional_id'] ?>" <?= $filterProfId == $p['professional_id'] ? 'selected' : '' ?>>
              <?= htmlspecialchars($p['name']) ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="col-md-2">
        <label class="form-label">Status</label>
        <select name="status" class="form-select">
          <option value="">All</option>
          <option value="pending" <?= $filterStatus === 'pending' ? 'selected' : '' ?>>Pending</option>
          <option value="confirmed" <?= $filterStatus === 'confirmed' ? 'selected' : '' ?>>Confirmed</option>
          <option value="completed" <?= $filterStatus === 'completed' ? 'selected' : '' ?>>Completed</option>
          <option value="cancelled" <?= $filterStatus === 'cancelled' ? 'selected' : '' ?>>Cancelled</option>
        </select>
      </div>
      <div class="col-md-3 d-flex align-items-end">
        <button class="btn btn-primary">Filter</button>
      </div>
    </form>
  </div>
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>#</th><th>Date</th><th>Time</th><th>Client</th><th>Professional</th><th>Status</th><th>Actions</th></tr>
  </thead>
  <tbody>
    <?php foreach ($reservations as $r): ?>
    <tr>
      <td><?= $r['reservation_id'] ?></td>
      <td><?= $r['date'] ?></td>
      <td><?= substr($r['time'], 0, 5) ?></td>
      <td><?= htmlspecialchars($r['ClientName']) ?></td>
      <td><?= htmlspecialchars($r['ProfessionalName']) ?></td>
      <td>
        <span class="badge bg-<?= $r['status'] === 'completed' ? 'success' : ($r['status'] === 'confirmed' ? 'primary' : ($r['status'] === 'pending' ? 'warning' : 'secondary')) ?>">
          <?= $r['status'] ?>
        </span>
      </td>
      <td>
        <button class="btn btn-sm btn-outline-success" data-bs-toggle="modal" data-bs-target="#payModal<?= $r['reservation_id'] ?>">
          <i class="bi bi-credit-card"></i> Pay
        </button>
        <form method="POST" class="d-inline" onsubmit="return confirm('Delete reservation #<?= $r['reservation_id'] ?>?')">
          <input type="hidden" name="delete_reservation" value="1">
          <input type="hidden" name="reservation_id" value="<?= $r['reservation_id'] ?>">
          <button class="btn btn-sm btn-outline-danger"><i class="bi bi-trash"></i></button>
        </form>

        <!-- Payment Modal -->
        <div class="modal fade" id="payModal<?= $r['reservation_id'] ?>">
          <div class="modal-dialog">
            <div class="modal-content">
              <form method="POST">
                <div class="modal-header">
                  <h5 class="modal-title">Add Payment - Reservation #<?= $r['reservation_id'] ?></h5>
                  <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                  <input type="hidden" name="add_payment" value="1">
                  <input type="hidden" name="reservation_id" value="<?= $r['reservation_id'] ?>">
                  <div class="mb-3">
                    <label class="form-label">Amount (&euro;)</label>
                    <input type="number" step="0.01" name="amount" class="form-control" required>
                  </div>
                  <div class="mb-3">
                    <label class="form-label">Method</label>
                    <select name="method" class="form-select">
                      <option value="card">Card</option>
                      <option value="cash">Cash</option>
                      <option value="paypal">PayPal</option>
                    </select>
                  </div>
                </div>
                <div class="modal-footer">
                  <button type="submit" class="btn btn-success">Add Payment</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<p class="text-muted"><?= count($reservations) ?> reservation(s)</p>

<?php if (!empty($auditLog)): ?>
<h4 class="mt-5"><i class="bi bi-journal-text"></i> Deletion Audit Log <small class="text-muted">(trg_LogReservationDeletion)</small></h4>
<table class="table table-sm bg-white shadow-sm">
  <thead class="table-secondary">
    <tr><th>Log ID</th><th>Res ID</th><th>User ID</th><th>Prof ID</th><th>Date</th><th>Status</th><th>Deleted At</th><th>Deleted By</th></tr>
  </thead>
  <tbody>
    <?php foreach ($auditLog as $log): ?>
    <tr>
      <td><?= $log['LogID'] ?></td>
      <td><?= $log['ReservationID'] ?></td>
      <td><?= $log['UserID'] ?></td>
      <td><?= $log['ProfessionalID'] ?></td>
      <td><?= $log['ReservationDate'] ?></td>
      <td><?= $log['Status'] ?></td>
      <td><?= $log['DeletedAt'] ?></td>
      <td><?= htmlspecialchars($log['DeletedBy']) ?></td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<?php endif; ?>

<?php include __DIR__ . '/../footer.php'; ?>
