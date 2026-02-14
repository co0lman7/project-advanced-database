<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

$startDate = $_GET['start_date'] ?? date('Y-01-01');
$endDate = $_GET['end_date'] ?? date('Y-12-31');
$categoryId = $_GET['category_id'] ?? '';

// sp_GetServiceFrequencyAnalysis
$stmt = $pdo->prepare("EXEC sp_GetServiceFrequencyAnalysis @StartDate=?, @EndDate=?, @CategoryID=?");
$stmt->execute([$startDate, $endDate, $categoryId ?: null]);
$report = $stmt->fetchAll();

$categories = $pdo->query("SELECT category_id, category_name FROM Category WHERE is_active = 1 ORDER BY category_name")->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-bar-chart"></i> Service Frequency Analysis</h2>
<p class="text-muted">Stored Procedure: <code>sp_GetServiceFrequencyAnalysis</code></p>

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
        <button class="btn btn-primary">Analyze</button>
      </div>
    </form>
  </div>
</div>

<?php if (!empty($report)): ?>
<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr>
      <th>Service</th><th>Category</th><th>Times Booked</th><th>Unique Clients</th>
      <th>Completed</th><th>Cancelled</th><th>Completion Rate</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach ($report as $r): ?>
    <tr>
      <td><strong><?= htmlspecialchars($r['service_name']) ?></strong></td>
      <td><span class="badge bg-info"><?= htmlspecialchars($r['category_name']) ?></span></td>
      <td><?= $r['TimesBooked'] ?></td>
      <td><?= $r['UniqueClients'] ?></td>
      <td><span class="text-success"><?= $r['CompletedBookings'] ?></span></td>
      <td><span class="text-danger"><?= $r['CancelledBookings'] ?></span></td>
      <td>
        <div class="progress" style="min-width:80px">
          <div class="progress-bar bg-success" style="width:<?= $r['CompletionRate'] ?>%">
            <?= $r['CompletionRate'] ?>%
          </div>
        </div>
      </td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
  <div class="alert alert-info">No booking data for the selected period.</div>
<?php endif; ?>

<?php include __DIR__ . '/../footer.php'; ?>
