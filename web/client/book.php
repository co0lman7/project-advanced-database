<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'client') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$uid = $_SESSION['user_id'];
$error = '';
$success = '';

// Get services with their professionals
$services = $pdo->query("
    SELECT ps.professional_id, ps.service_id, s.service_name, ps.custom_price,
           u.firstname + ' ' + u.lastname AS prof_name, p.professional_id AS pid
    FROM ProfessionalService ps
    JOIN Service s ON ps.service_id = s.service_id
    JOIN Professional p ON ps.professional_id = p.professional_id
    JOIN [User] u ON p.user_id = u.user_id
    WHERE s.is_active = 1 AND p.is_verified = 1
    ORDER BY s.service_name, prof_name
")->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $serviceId = (int)($_POST['service_id'] ?? 0);
    $profId = (int)($_POST['professional_id'] ?? 0);
    $date = $_POST['date'] ?? '';
    $time = $_POST['time'] ?? '';

    if ($serviceId && $profId && $date && $time) {
        try {
            // This goes through trg_PreventDoubleReservation (INSTEAD OF INSERT)
            $stmt = $pdo->prepare("
                INSERT INTO Reservation (user_id, professional_id, service_id, [date], [time], status)
                VALUES (?, ?, ?, ?, ?, 'pending')
            ");
            $stmt->execute([$uid, $profId, $serviceId, $date, $time]);
            $success = 'Reservation booked successfully!';
        } catch (PDOException $e) {
            // Trigger raises error on conflict
            if (strpos($e->getMessage(), 'conflicts') !== false) {
                $error = 'This time slot is already taken for this professional. Please choose a different date/time.';
            } else {
                $error = 'Booking failed: ' . $e->getMessage();
            }
        }
    } else {
        $error = 'Please fill in all fields.';
    }
}

$preselectedService = $_GET['service'] ?? '';

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-calendar-plus"></i> Book a Service</h2>
<p class="text-muted">Trigger: <code>trg_PreventDoubleReservation</code> prevents double-booking</p>

<?php if ($error): ?>
  <div class="alert alert-danger"><i class="bi bi-exclamation-triangle"></i> <?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><i class="bi bi-check-circle"></i> <?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="card shadow-sm">
  <div class="card-body">
    <form method="POST">
      <div class="row g-3">
        <div class="col-md-6">
          <label class="form-label">Service & Professional</label>
          <select name="service_professional" class="form-select" id="serviceProfSelect" required>
            <option value="">-- Select --</option>
            <?php foreach ($services as $s): ?>
              <option value="<?= $s['service_id'] ?>|<?= $s['professional_id'] ?>"
                <?= ($preselectedService == $s['service_id']) ? 'selected' : '' ?>>
                <?= htmlspecialchars($s['service_name']) ?> - <?= htmlspecialchars($s['prof_name']) ?>
                (&euro;<?= number_format($s['custom_price'], 2) ?>)
              </option>
            <?php endforeach; ?>
          </select>
          <input type="hidden" name="service_id" id="serviceId">
          <input type="hidden" name="professional_id" id="profId">
        </div>
        <div class="col-md-3">
          <label class="form-label">Date</label>
          <input type="date" name="date" class="form-control" required
                 min="<?= date('Y-m-d') ?>"
                 value="<?= htmlspecialchars($_POST['date'] ?? '') ?>">
        </div>
        <div class="col-md-3">
          <label class="form-label">Time</label>
          <input type="time" name="time" class="form-control" required
                 value="<?= htmlspecialchars($_POST['time'] ?? '') ?>">
        </div>
      </div>
      <button type="submit" class="btn btn-success mt-3">
        <i class="bi bi-calendar-check"></i> Book Reservation
      </button>
    </form>
  </div>
</div>

<script>
document.getElementById('serviceProfSelect').addEventListener('change', function() {
  const parts = this.value.split('|');
  document.getElementById('serviceId').value = parts[0] || '';
  document.getElementById('profId').value = parts[1] || '';
});
// Trigger on load for preselected
document.getElementById('serviceProfSelect').dispatchEvent(new Event('change'));
</script>

<?php include __DIR__ . '/../footer.php'; ?>
