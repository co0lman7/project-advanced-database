<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'admin') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

// vw_ClientLoyaltyOverview + fn_GetUserLoyaltyTier
$clients = $pdo->query("
    SELECT clo.*, dbo.fn_GetUserLoyaltyTier(clo.user_id) AS LoyaltyTier
    FROM vw_ClientLoyaltyOverview clo
    ORDER BY clo.CompletedReservations DESC
")->fetchAll();

// Tier summary
$tiers = ['Platinum' => 0, 'Gold' => 0, 'Silver' => 0, 'Bronze' => 0];
foreach ($clients as $c) {
    if (isset($tiers[$c['LoyaltyTier']])) $tiers[$c['LoyaltyTier']]++;
}

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-award"></i> Client Loyalty Overview</h2>
<p class="text-muted">View: <code>vw_ClientLoyaltyOverview</code> + Function: <code>fn_GetUserLoyaltyTier</code></p>

<div class="row g-4 mb-4">
  <?php foreach ($tiers as $tier => $count): ?>
  <div class="col-md-3">
    <div class="card shadow-sm text-center">
      <div class="card-body">
        <h5><span class="badge badge-<?= strtolower($tier) ?> fs-6"><?= $tier ?></span></h5>
        <h3><?= $count ?></h3>
        <small class="text-muted">clients</small>
      </div>
    </div>
  </div>
  <?php endforeach; ?>
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>Client</th><th>Completed Reservations</th><th>Loyalty Tier</th></tr>
  </thead>
  <tbody>
    <?php foreach ($clients as $c): ?>
    <tr>
      <td><?= htmlspecialchars($c['ClientName']) ?></td>
      <td><?= $c['CompletedReservations'] ?></td>
      <td><span class="badge badge-<?= strtolower($c['LoyaltyTier']) ?>"><?= $c['LoyaltyTier'] ?></span></td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>

<div class="card shadow-sm mt-4">
  <div class="card-header"><strong>Tier Requirements</strong></div>
  <div class="card-body">
    <ul class="list-unstyled mb-0">
      <li><span class="badge badge-bronze">Bronze</span> 0-4 completed reservations</li>
      <li><span class="badge badge-silver">Silver</span> 5-14 completed reservations</li>
      <li><span class="badge badge-gold">Gold</span> 15-29 completed reservations</li>
      <li><span class="badge badge-platinum">Platinum</span> 30+ completed reservations</li>
    </ul>
  </div>
</div>

<?php include __DIR__ . '/../footer.php'; ?>
