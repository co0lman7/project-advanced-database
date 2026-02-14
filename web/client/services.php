<?php
session_start();
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'client') { header("Location: /web/index.php"); exit; }
require __DIR__ . '/../db.php';
$baseUrl = '/web';

$categoryFilter = $_GET['category'] ?? '';

$query = "SELECT * FROM vw_ServiceCatalog";
$params = [];
if ($categoryFilter) {
    $query .= " WHERE category_name = ?";
    $params[] = $categoryFilter;
}
$query .= " ORDER BY category_name, service_name";

$stmt = $pdo->prepare($query);
$stmt->execute($params);
$services = $stmt->fetchAll();

$categories = $pdo->query("SELECT DISTINCT category_name FROM vw_ServiceCatalog ORDER BY category_name")->fetchAll();

include __DIR__ . '/../header.php';
?>

<h2 class="mb-4"><i class="bi bi-grid"></i> Service Catalog</h2>
<p class="text-muted">Data source: <code>vw_ServiceCatalog</code></p>

<form method="GET" class="row g-3 mb-4">
  <div class="col-md-4">
    <select name="category" class="form-select">
      <option value="">All Categories</option>
      <?php foreach ($categories as $c): ?>
        <option value="<?= htmlspecialchars($c['category_name']) ?>"
          <?= $categoryFilter === $c['category_name'] ? 'selected' : '' ?>>
          <?= htmlspecialchars($c['category_name']) ?>
        </option>
      <?php endforeach; ?>
    </select>
  </div>
  <div class="col-md-2">
    <button class="btn btn-primary">Filter</button>
  </div>
</form>

<div class="row g-4">
  <?php foreach ($services as $s): ?>
  <div class="col-md-4">
    <div class="card shadow-sm h-100">
      <div class="card-body">
        <span class="badge bg-info mb-2"><?= htmlspecialchars($s['category_name']) ?></span>
        <h5><?= htmlspecialchars($s['service_name']) ?></h5>
        <p class="text-muted small"><?= htmlspecialchars($s['description']) ?></p>
        <p><strong>Professional:</strong> <?= htmlspecialchars($s['ProfessionalName']) ?>
          (<?= $s['experience_years'] ?> yrs)</p>
        <p><strong>Price:</strong> &euro;<?= number_format($s['custom_price'] ?? $s['base_price'], 2) ?></p>
        <?php if ($s['AverageRating']): ?>
          <p><strong>Rating:</strong> <?= number_format($s['AverageRating'], 1) ?>/5
            (<?= $s['ReviewCount'] ?> reviews)</p>
        <?php else: ?>
          <p class="text-muted"><em>No reviews yet</em></p>
        <?php endif; ?>
      </div>
      <div class="card-footer">
        <a href="/web/client/book.php?service=<?= $s['service_id'] ?>&professional=<?= htmlspecialchars($s['ProfessionalName']) ?>"
           class="btn btn-sm btn-success w-100">Book Now</a>
      </div>
    </div>
  </div>
  <?php endforeach; ?>
</div>

<?php if (empty($services)): ?>
  <div class="alert alert-info">No services found.</div>
<?php endif; ?>

<?php include __DIR__ . '/../footer.php'; ?>
