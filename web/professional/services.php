<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'professional') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';
$profId = $_SESSION['professional_id'] ?? 0;
$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $serviceId = (int)($_POST['service_id'] ?? 0);
    $customPrice = (float)($_POST['custom_price'] ?? 0);

    if ($serviceId && $customPrice > 0) {
        try {
            $stmt = $pdo->prepare("
                INSERT INTO ProfessionalService (professional_id, service_id, custom_price)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$profId, $serviceId, $customPrice]);
            $success = 'Service added to your offerings!';
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'PRIMARY') !== false || strpos($e->getMessage(), 'duplicate') !== false) {
                $error = 'You already offer this service.';
            } else {
                $error = 'Failed: ' . $e->getMessage();
            }
        }
    } else {
        $error = 'Please select a service and set a price.';
    }
}

// Current services
$myServices = $pdo->prepare("
    SELECT ps.service_id, s.service_name, s.base_price, ps.custom_price, c.category_name
    FROM ProfessionalService ps
    JOIN Service s ON ps.service_id = s.service_id
    JOIN Category c ON s.category_id = c.category_id
    WHERE ps.professional_id = ?
    ORDER BY c.category_name, s.service_name
");
$myServices->execute([$profId]);
$current = $myServices->fetchAll();

// Available services to add
$allServices = $pdo->query("SELECT service_id, service_name, base_price FROM Service WHERE is_active = 1 ORDER BY service_name")->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-wrench"></i> My Services</h2>

<?php if ($error): ?>
  <div class="alert alert-danger"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>
<?php if ($success): ?>
  <div class="alert alert-success"><?= htmlspecialchars($success) ?></div>
<?php endif; ?>

<div class="card shadow-sm mb-4">
  <div class="card-header"><strong>Add a Service</strong></div>
  <div class="card-body">
    <form method="POST" class="row g-3">
      <div class="col-md-6">
        <label class="form-label">Service</label>
        <select name="service_id" class="form-select" required>
          <option value="">-- Select --</option>
          <?php foreach ($allServices as $s): ?>
            <option value="<?= $s['service_id'] ?>">
              <?= htmlspecialchars($s['service_name']) ?> (base: &euro;<?= number_format($s['base_price'], 2) ?>)
            </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="col-md-3">
        <label class="form-label">Your Price (&euro;)</label>
        <input type="number" step="0.01" min="0.01" name="custom_price" class="form-control" required>
      </div>
      <div class="col-md-3 d-flex align-items-end">
        <button class="btn btn-success w-100">Add Service</button>
      </div>
    </form>
  </div>
</div>

<table class="table table-hover bg-white shadow-sm">
  <thead class="table-dark">
    <tr><th>Category</th><th>Service</th><th>Base Price</th><th>Your Price</th></tr>
  </thead>
  <tbody>
    <?php foreach ($current as $s): ?>
    <tr>
      <td><span class="badge bg-info"><?= htmlspecialchars($s['category_name']) ?></span></td>
      <td><?= htmlspecialchars($s['service_name']) ?></td>
      <td>&euro;<?= number_format($s['base_price'], 2) ?></td>
      <td><strong>&euro;<?= number_format($s['custom_price'], 2) ?></strong></td>
    </tr>
    <?php endforeach; ?>
  </tbody>
</table>

<?php include __DIR__ . '/../footer.php'; ?>
