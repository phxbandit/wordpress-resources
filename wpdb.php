<?php
require 'wp-load.php';

// Self-delete
if (isset($_POST['delete_me'])) {
    @unlink(__FILE__);
    die('Script deleted');
}
?>

Name: <?= DB_NAME ?><br>
User: <?= DB_USER ?><br>
Pass: <?= DB_PASSWORD ?><br>
Host: <?= DB_HOST ?><br>
Prefix: <?= $table_prefix ?><br><br>

<form method="POST" onsubmit="return confirm('Delete this script?')">
    <button name="delete_me" value="1" style="background:red;color:#fff;padding:10px 20px;border:none;cursor:pointer;">
        Delete This Script
    </button>
</form>
