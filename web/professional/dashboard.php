<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'professional') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$profId = $_SESSION['professional_id'] ?? 0;

// vw_ProfessionalDashboard
$stmt = $pdo->prepare("SELECT * FROM vw_ProfessionalDashboard WHERE professional_id = ?");
$stmt->execute([$profId]);
$dashboard = $stmt->fetch();

// fn_GetProfessionalEarnings with date filter
$startDate = $_GET['start_date'] ?? date('Y-01-01');
$endDate = $_GET['end_date'] ?? date('Y-12-31');

$stmt = $pdo->prepare("SELECT dbo.fn_GetProfessionalEarnings(?, ?, ?) AS earnings");
$stmt->execute([$profId, $startDate, $endDate]);
$filteredEarnings = $stmt->fetchColumn();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4">Professional Dashboard</h2>
<p class="text-muted">Data: <code>vw_ProfessionalDashboard</code> + <code>fn_GetProfessionalEarnings</code></p>

<div class="row g-4 mb-4">
  <div class="col-md-3">
    <div class="card card-stat shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Total Reservations</h6>
        <h3><?= $dashboard['TotalReservations'] ?? 0 ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat green shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Completed</h6>
        <h3><?= $dashboard['CompletedReservations'] ?? 0 ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat purple shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Average Rating</h6>
        <h3><?= $dashboard['AverageRating'] ? number_format($dashboard['AverageRating'], 1) . '/5' : 'N/A' ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat green shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Total Earnings</h6>
        <h3>&euro;<?= number_format($dashboard['TotalEarnings'] ?? 0, 2) ?></h3>
      </div>
    </div>
  </div>
</div>

<div class="card shadow-sm mb-4">
  <div class="card-header"><strong>Earnings Calculator</strong> <code>fn_GetProfessionalEarnings</code></div>
  <div class="card-body">
    <form method="GET" class="row g-3">
      <div class="col-md-4">
        <label class="form-label">Start Date</label>
        <input type="date" name="start_date" class="form-control" value="<?= htmlspecialchars($startDate) ?>">
      </div>
      <div class="col-md-4">
        <label class="form-label">End Date</label>
        <input type="date" name="end_date" class="form-control" value="<?= htmlspecialchars($endDate) ?>">
      </div>
      <div class="col-md-4 d-flex align-items-end">
        <button class="btn btn-primary">Calculate</button>
      </div>
    </form>
    <div class="mt-3">
      <h4>Earnings: <span class="text-success">&euro;<?= number_format($filteredEarnings, 2) ?></span></h4>
      <small class="text-muted"><?= $startDate ?> to <?= $endDate ?></small>
    </div>
  </div>
</div>

<?php include __DIR__ . '/../footer.php'; ?>
