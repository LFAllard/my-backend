#!/usr/bin/env php
<?php
/**
 * 🏭 THE SEED FACTORY (V14.2 - Persona Edition)
 * Rensad från systemkonfiguration - fokuserar enbart på test-personas.
 */

$projectRoot = dirname(__DIR__);
$autoload = $projectRoot . '/backend/php/vendor/autoload.php';
if (!file_exists($autoload)) die("❌ Error: Run 'composer install'\n");
require $autoload;

use Defuse\Crypto\Crypto;
use Defuse\Crypto\Key;

// --- 1. Miljöhantering ---
$envFile = $projectRoot . '/backend/php/.env';
if (!file_exists($envFile)) die("❌ Error: .env file missing at $envFile\n");

$lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
$loadedEnv = [];
foreach ($lines as $line) {
    if (strpos(trim($line), '#') === 0) continue;
    $parts = explode('=', $line, 2);
    if (count($parts) === 2) {
        $loadedEnv[trim($parts[0])] = trim(trim($parts[1]), "\"'");
    }
}

$hmacSecret   = $loadedEnv['HMAC_SECRET_KEY'] ?? null;
$defuseKeyStr = $loadedEnv['EMAIL_ENCRYPTION_KEY'] ?? null;

if (!$hmacSecret || !$defuseKeyStr) die("❌ Error: Missing keys in .env\n");

$encryptionKey = Key::loadFromAsciiSafeString($defuseKeyStr);

$outputFile = $projectRoot . '/supabase/seed.sql';
$securePlaceholder = password_hash('dev-only-password', PASSWORD_BCRYPT);
$isoNow = date('c'); 

// --- 2. Definition av Personas ---
$personas = [
    ['id' => 1, 'email' => 'admin@finnas.se',   'roles' => ['super_admin']],
    ['id' => 2, 'email' => 'scholar@finnas.se', 'roles' => ['scholar']],
    ['id' => 3, 'email' => 'user@finnas.se',    'roles' => ['user']],
];

// Generera resterande testanvändare (upp till 43 totalt)
for ($i = 4; $i <= 43; $i++) {
    $personas[] = ['id' => $i, 'email' => "tester_{$i}@finnas.se", 'roles' => ['user']];
}

$sql = "-- 🛡️ AUTO-GENERATED PERSONA SEED (V14.2)\n";
$sql .= "-- Denna fil innehåller endast testdata. Systeminställningar sköts via migrationer.\n";
$sql .= "BEGIN;\n\n";

// --- 3. Generering av rader ---
$uRows = []; $lRows = []; $rRows = [];
foreach ($personas as $p) {
    $email = strtolower(trim($p['email']));
    $hexHmac = bin2hex(hash_hmac('sha256', $email, $hmacSecret, true));
    $encryptedEmail = Crypto::encrypt($email, $encryptionKey);

    $uRows[] = "({$p['id']}, '{$email}', '{$securePlaceholder}', '{$isoNow}', '{$isoNow}')";
    $lRows[] = "({$p['id']}, decode('{$hexHmac}', 'hex'), '{$encryptedEmail}')";
    foreach ($p['roles'] as $role) {
        $rRows[] = "({$p['id']}, '{$role}', 'global')";
    }
}

// --- 4. SQL-generering ---

// Användare
$sql .= "-- Tabell: aaaaff_ljus_users\n";
$sql .= "INSERT INTO aaaaff_ljus_users (id, email, password, registered, force_logout_before) VALUES \n" 
      . implode(",\n", $uRows) . "\nON CONFLICT (id) DO NOTHING;\n\n";

// Email Lookup (PII-skydd)
$sql .= "-- Tabell: aaaafm_ljus_email_lookup\n";
$sql .= "INSERT INTO aaaafm_ljus_email_lookup (user_id, email_hash, encrypted_email) VALUES \n" 
      . implode(",\n", $lRows) . "\nON CONFLICT (user_id) DO NOTHING;\n\n";

// Roller
$sql .= "-- Tabell: aaaaft_roles\n";
$sql .= "INSERT INTO aaaaft_roles (user_id, role_key, scope_key) VALUES \n" 
      . implode(",\n", $rRows) . "\nON CONFLICT (user_id, role_key, scope_key) DO NOTHING;\n\n";

$sql .= "COMMIT;";

file_put_contents($outputFile, $sql);
echo "✅ Seed Factory V14.2 complete. Generated " . count($personas) . " personas in supabase/seed.sql\n";