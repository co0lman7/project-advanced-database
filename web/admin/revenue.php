<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

$startDate = $_GET['start_date'] ?? date('Y-01-01');
$endDate = $_GET['end_date'] ?? date('Y-12-31');
$categoryId = $_GET['category_id'] ?? '';

// sp_GetRevenueReport
$stmt = $pdo->prepare("EXEC sp_GetRevenueReport @StartDate=?, @EndDate=?, @CategoryID=?");
$stmt->execute([$startDate, $endDate, $categoryId ?: null]);
$report = $stmt->fetchAll();

$categories = $pdo->query("SELECT category_id, category_name FROM Category WHERE is_active = 1 ORDER BY category_name")->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-cash-stack"></i> Revenue Report</h2>
<p class="text-muted">Stored Procedure: <code>sp_GetRevenueReport</code></p>

<div class="card shadow-sm mb-4">
  <div class="card-body">
    <form method="GET" class="row g-3">
      <div class="col-md-3">
        <label class="form-label">Start Date</label>
        <input type="date" name="start_date" class="form-control" value="<?= htmlspecialchars($startDate) ?>">
      </div>
      <div class="col-md-3">
        <label class="form-label">End Date</label>
        <input type="date" name="end_date" class="form-control" value="<?= htmlspecialchars($endDate) ?>">
      </div>
      <div class="col-md-3">
        <label class="form-label">Category</label>
        <select name="category_id" class="form-select">
          <option value="">All Categories</option>
          <?php foreach ($categories as $c): ?>
            <option value="<?= $c['category_id'] ?>" <?= $categoryId == $c['category_id'] ? 'selected' : '' ?>>
              <?= htmlspecialchars($c['category_name']) ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="col-md-3 d-flex align-items-end">
        <button class="btn btn-primary">Generate Report</button>
      </div>
    </form>
  </div>
</div>

<?php if (!empty($report)): ?>
<?php $grandTotal = array_sum(array_column($report, 'TotalRevenue')); ?>
<div class="alert alert-success">
  <strong>Grand Total Revenue: &euro;<?= number_format($grandTotal, 2) ?></strong>
  (<?= $startDate ?> to <?= $endDate ?>)
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>Category</th><th>Reservations</th><th>Unique Clients</th><th>Total Revenue</th><th>Avg Reservation Value</th></tr>
  </thead>
  <tbody>
    <?php foreach ($report as $r): ?>
    <tr>
      <td><strong><?= htmlspecialchars($r['category_name']) ?></strong></td>
      <td><?= $r['TotalReservations'] ?></td>
      <td><?= $r['UniqueClients'] ?></td>
      <td>&euro;<?= number_format($r['TotalRevenue'], 2) ?></td>
      <td>&euro;<?= number_format($r['AverageReservationValue'], 2) ?></td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
  <div class="alert alert-info">No revenue data for the selected period.</div>
<?php endif; ?>

<?php include __DIR__ . '/../footer.php'; ?>
