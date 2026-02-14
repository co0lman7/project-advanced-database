<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'client') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$uid = $_SESSION['user_id'];

// fn_GetUserLoyaltyTier
$tier = $pdo->prepare("SELECT dbo.fn_GetUserLoyaltyTier(?) AS tier");
$tier->execute([$uid]);
$loyaltyTier = $tier->fetchColumn();

// fn_GetUserReservationCount - all
$stmt = $pdo->prepare("SELECT dbo.fn_GetUserReservationCount(?, NULL) AS cnt");
$stmt->execute([$uid]);
$totalRes = $stmt->fetchColumn();

// fn_GetUserReservationCount - completed
$stmt = $pdo->prepare("SELECT dbo.fn_GetUserReservationCount(?, 'completed') AS cnt");
$stmt->execute([$uid]);
$completedRes = $stmt->fetchColumn();

// fn_GetUserReservationCount - pending
$stmt = $pdo->prepare("SELECT dbo.fn_GetUserReservationCount(?, 'pending') AS cnt");
$stmt->execute([$uid]);
$pendingRes = $stmt->fetchColumn();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4">Welcome, <?= htmlspecialchars($_SESSION['firstname']) ?>!</h2>

<div class="row g-4 mb-4">
  <div class="col-md-3">
    <div class="card card-stat shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Loyalty Tier</h6>
        <h3><span class="badge badge-<?= strtolower($loyaltyTier) ?>"><?= $loyaltyTier ?></span></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat green shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Total Reservations</h6>
        <h3><?= $totalRes ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Completed</h6>
        <h3><?= $completedRes ?></h3>
      </div>
    </div>
  </div>
  <div class="col-md-3">
    <div class="card card-stat orange shadow-sm">
      <div class="card-body">
        <h6 class="text-muted">Pending</h6>
        <h3><?= $pendingRes ?></h3>
      </div>
    </div>
  </div>
</div>

<div class="row g-4">
  <div class="col-md-6">
    <div class="card shadow-sm">
      <div class="card-body text-center">
        <h5>Browse Services</h5>
        <p class="text-muted">Find and book professional services</p>
        <a href="/web/client/services.php" class="btn btn-primary">View Services</a>
      </div>
    </div>
  </div>
  <div class="col-md-6">
    <div class="card shadow-sm">
      <div class="card-body text-center">
        <h5>My Reservations</h5>
        <p class="text-muted">View and manage your bookings</p>
        <a href="/web/client/reservations.php" class="btn btn-outline-primary">View Reservations</a>
      </div>
    </div>
  </div>
</div>

<?php include __DIR__ . '/../footer.php'; ?>
