<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

// vw_AdminSystemOverview
$overview = $pdo->query("SELECT * FROM vw_AdminSystemOverview")->fetch();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-speedometer2"></i> Admin Dashboard</h2>
<p class="text-muted">Data source: <code>vw_AdminSystemOverview</code></p>

<div class="row g-4 mb-4">
  <div class="col-md-3">
    <div class="card card-stat shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Total Users</h6>
        <h3><?= $overview['TotalUsers'] ?></h3>
        <small><?= $overview['TotalClients'] ?> clients, <?= $overview['TotalProfessionals'] ?> professionals</small>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat green shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Total Revenue</h6>
        <h3>&euro;<?= number_format($overview['TotalRevenue'], 2) ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat purple shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Avg Rating</h6>
        <h3><?= $overview['OverallAverageRating'] ? number_format($overview['OverallAverageRating'], 1) . '/5' : 'N/A' ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat orange shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Pending</h6>
        <h3><?= $overview['PendingReservations'] ?></h3>
      </div>
    </div>
  </div>
</div>

<div class="row g-4">
  <div class="col-md-6">
    <div class="card shadow-sm">
      <div class="card-header"><strong>Reservation Status Breakdown</strong></div>
      <div class="card-body">
        <table class="table table-sm mb-0">
          <tr><td>Completed</td><td><span class="badge bg-success"><?= $overview['CompletedReservations'] ?></span></td></tr>
          <tr><td>Confirmed</td><td><span class="badge bg-primary"><?= $overview['ConfirmedReservations'] ?></span></td></tr>
          <tr><td>Pending</td><td><span class="badge bg-warning"><?= $overview['PendingReservations'] ?></span></td></tr>
          <tr><td>Cancelled</td><td><span class="badge bg-secondary"><?= $overview['CancelledReservations'] ?></span></td></tr>
        </table>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card shadow-sm">
      <div class="card-header"><strong>Quick Links</strong></div>
      <div class="card-body">
        <a href="/web/admin/users.php" class="btn btn-outline-primary me-2 mb-2"><i class="bi bi-people"></i> Manage Users</a>
        <a href="/web/admin/reservations.php" class="btn btn-outline-primary me-2 mb-2"><i class="bi bi-calendar3"></i> Reservations</a>
        <a href="/web/admin/revenue.php" class="btn btn-outline-success me-2 mb-2"><i class="bi bi-cash-stack"></i> Revenue Report</a>
        <a href="/web/admin/frequency.php" class="btn btn-outline-info me-2 mb-2"><i class="bi bi-bar-chart"></i> Service Frequency</a>
        <a href="/web/admin/loyalty.php" class="btn btn-outline-warning me-2 mb-2"><i class="bi bi-award"></i> Client Loyalty</a>
      </div>
    </div>
  </div>
</div>

<?php include __DIR__ . '/../footer.php'; ?>
