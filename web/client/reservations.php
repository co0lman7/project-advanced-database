<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'client') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$uid = $_SESSION['user_id'];

$reservations = $pdo->prepare("
    SELECT r.reservation_id, r.[date], r.[time], r.status, r.created_at,
           s.service_name, u.firstname + ' ' + u.lastname AS prof_name,
           p.amount, p.payment_status,
           rev.rating, rev.comment
    FROM Reservation r
    JOIN Service s ON r.service_id = s.service_id
    JOIN Professional pr ON r.professional_id = pr.professional_id
    JOIN [User] u ON pr.user_id = u.user_id
    LEFT JOIN Payment p ON r.reservation_id = p.reservation_id
    LEFT JOIN Review rev ON r.reservation_id = rev.reservation_id
    WHERE r.user_id = ?
    ORDER BY r.[date] DESC, r.[time] DESC
");
$reservations->execute([$uid]);
$rows = $reservations->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-list-check"></i> My Reservations</h2>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr>
      <th>#</th>
      <th>Service</th>
      <th>Professional</th>
      <th>Date</th>
      <th>Time</th>
      <th>Status</th>
      <th>Payment</th>
      <th>Review</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    <?php foreach ($rows as $r): ?>
    <tr>
      <td><?= $r['reservation_id'] ?></td>
      <td><?= htmlspecialchars($r['service_name']) ?></td>
      <td><?= htmlspecialchars($r['prof_name']) ?></td>
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
        <?php if ($r['amount']): ?>
          &euro;<?= number_format($r['amount'], 2) ?>
          <span class="badge bg-<?= $r['payment_status'] === 'paid' ? 'success' : ($r['payment_status'] === 'failed' ? 'danger' : 'warning') ?>">
            <?= $r['payment_status'] ?>
          </span>
        <?php else: ?>
          <span class="text-muted">-</span>
        <?php endif; ?>
      </td>
      <td>
        <?php if ($r['rating']): ?>
          <?= str_repeat('&#9733;', $r['rating']) ?><?= str_repeat('&#9734;', 5 - $r['rating']) ?>
        <?php else: ?>
          -
        <?php endif; ?>
      </td>
      <td>
        <?php if ($r['status'] === 'completed' && !$r['rating']): ?>
          <a href="/web/client/review.php?reservation_id=<?= $r['reservation_id'] ?>"
             class="btn btn-sm btn-outline-primary">Review</a>
        <?php endif; ?>
      </td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>

<?php if (empty($rows)): ?>
  <div class="alert alert-info">You have no reservations yet. <a href="/web/client/services.php">Browse services</a></div>
<?php endif; ?>

<?php include __DIR__ . '/../footer.php'; ?>
