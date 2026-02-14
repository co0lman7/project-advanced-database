<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'client') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$error = '';
$success = '';

$reservationId = (int)($_GET['reservation_id'] ?? $_POST['reservation_id'] ?? 0);

// Get reservation details
$stmt = $pdo->prepare("
    SELECT r.reservation_id, r.status, r.[date], s.service_name,
           u.firstname + ' ' + u.lastname AS prof_name
    FROM Reservation r
    JOIN Service s ON r.service_id = s.service_id
    JOIN Professional p ON r.professional_id = p.professional_id
    JOIN [User] u ON p.user_id = u.user_id
    WHERE r.reservation_id = ? AND r.user_id = ?
");
$stmt->execute([$reservationId, $_SESSION['user_id']]);
$reservation = $stmt->fetch();

if (!$reservation) {
    header("Location: /web/client/reservations.php");
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $rating = (int)($_POST['rating'] ?? 0);
    $comment = trim($_POST['comment'] ?? '');

    if ($rating >= 1 && $rating <= 5) {
        try {
            // This goes through trg_ValidateReview (INSTEAD OF INSERT)
            // Will fail if reservation is not 'completed'
            $stmt = $pdo->prepare("INSERT INTO Review (reservation_id, rating, comment) VALUES (?, ?, ?)");
            $stmt->execute([$reservationId, $rating, $comment]);
            $success = 'Review submitted successfully!';
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'completed') !== false) {
                $error = 'Reviews can only be submitted for completed reservations.';
            } else {
                $error = 'Failed to submit review: ' . $e->getMessage();
            }
        }
    } else {
        $error = 'Please select a rating between 1 and 5.';
    }
}

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-star"></i> Submit Review</h2>
<p class="text-muted">Trigger: <code>trg_ValidateReview</code> only allows reviews for completed reservations</p>

<?php if ($error): ?>
  <div class="alert alert-danger"><i class="bi bi-exclamation-triangle"></i> <?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><i class="bi bi-check-circle"></i> <?= htmlspecialchars($success) ?>
    <a href="/web/client/reservations.php">Back to reservations</a></div>
<?php endif; ?>

<div class="card shadow-sm">
  <div class="card-body">
    <h5>Reservation #<?= $reservation['reservation_id'] ?></h5>
    <p><strong>Service:</strong> <?= htmlspecialchars($reservation['service_name']) ?></p>
    <p><strong>Professional:</strong> <?= htmlspecialchars($reservation['prof_name']) ?></p>
    <p><strong>Date:</strong> <?= $reservation['date'] ?></p>
    <p><strong>Status:</strong>
      <span class="badge bg-<?= $reservation['status'] === 'completed' ? 'success' : 'warning' ?>">
        <?= $reservation['status'] ?>
      </span>
    </p>

    <?php if (!$success): ?>
    <hr>
    <form method="POST">
      <input type="hidden" name="reservation_id" value="<?= $reservationId ?>">
      <div class="mb-3">
        <label class="form-label">Rating</label>
        <div class="btn-group" role="group">
          <?php for ($i = 1; $i <= 5; $i++): ?>
            <input type="radio" class="btn-check" name="rating" id="r<?= $i ?>" value="<?= $i ?>" <?= $i === 5 ? 'checked' : '' ?>>
            <label class="btn btn-outline-warning" for="r<?= $i ?>"><?= str_repeat('&#9733;', $i) ?></label>
          <?php endfor; ?>
        </div>
      </div>
      <div class="mb-3">
        <label class="form-label">Comment</label>
        <textarea name="comment" class="form-control" rows="3" placeholder="Write your review..."></textarea>
      </div>
      <button type="submit" class="btn btn-primary">Submit Review</button>
    </form>
    <?php endif; ?>
  </div>
</div>

<?php include __DIR__ . '/../footer.php'; ?>
