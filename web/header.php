<?php
if (session_status() === PHP_SESSION_NONE) session_start();
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Professional Services Booking</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="<?= isset($baseUrl) ? $baseUrl : '' ?>/assets/style.css" rel="stylesheet">
</head>
<body>
<?php if (isset($_SESSION['user_id'])): ?>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark mb-4">
  <div class="container">
    <a class="navbar-brand" href="/web/<?= $_SESSION['role'] ?>/dashboard.php">
      <i class="bi bi-tools"></i> ProServices
    </a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMain">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navMain">
      <ul class="navbar-nav me-auto">
        <?php if ($_SESSION['role'] === 'client'): ?>
          <li class="nav-item"><a class="nav-link" href="/web/client/dashboard.php">Dashboard</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/client/services.php">Services</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/client/reservations.php">My Reservations</a></li>
        <?php elseif ($_SESSION['role'] === 'professional'): ?>
          <li class="nav-item"><a class="nav-link" href="/web/professional/dashboard.php">Dashboard</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/professional/reservations.php">Reservations</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/professional/availability.php">Availability</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/professional/services.php">My Services</a></li>
        <?php elseif ($_SESSION['role'] === 'admin'): ?>
          <li class="nav-item"><a class="nav-link" href="/web/admin/dashboard.php">Dashboard</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/admin/users.php">Users</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/admin/reservations.php">Reservations</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/admin/revenue.php">Revenue</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/admin/frequency.php">Service Frequency</a></li>
          <li class="nav-item"><a class="nav-link" href="/web/admin/loyalty.php">Client Loyalty</a></li>
        <?php endif; ?>
      </ul>
      <span class="navbar-text me-3">
        <i class="bi bi-person-circle"></i> <?= htmlspecialchars($_SESSION['firstname'] . ' ' . $_SESSION['lastname']) ?>
        <span class="badge bg-secondary"><?= $_SESSION['role'] ?></span>
      </span>
      <a href="/web/logout.php" class="btn btn-outline-light btn-sm">Logout</a>
    </div>
  </div>
</nav>
<?php endif; ?>
<div class="container">
