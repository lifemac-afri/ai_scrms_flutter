<?php
$token = $_GET['token'] ?? '';
if (!$token) { http_response_code(400); exit; }
$url = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" . urlencode($token) . "&bgcolor=ffffff&color=0a0f1e&margin=10&format=png&ecc=M";
$ctx = stream_context_create(['http' => ['timeout' => 6, 'ignore_errors' => true]]);
$img = @file_get_contents($url, false, $ctx);
if ($img && strlen($img) > 100) {
    header('Content-Type: image/png');
    header('Cache-Control: public, max-age=86400');
    echo $img;
} else {
    // Offline SVG fallback
    header('Content-Type: image/svg+xml');
    $t = htmlspecialchars(substr($token, 0, 8));
    echo <<<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
<rect width="200" height="200" fill="white" rx="8"/>
<rect x="10" y="10" width="60" height="60" fill="none" stroke="#0a0f1e" stroke-width="4"/>
<rect x="22" y="22" width="36" height="36" fill="#0a0f1e"/>
<rect x="130" y="10" width="60" height="60" fill="none" stroke="#0a0f1e" stroke-width="4"/>
<rect x="142" y="22" width="36" height="36" fill="#0a0f1e"/>
<rect x="10" y="130" width="60" height="60" fill="none" stroke="#0a0f1e" stroke-width="4"/>
<rect x="22" y="142" width="36" height="36" fill="#0a0f1e"/>
<rect x="80" y="10" width="8" height="8" fill="#0a0f1e"/><rect x="92" y="10" width="8" height="8" fill="#0a0f1e"/>
<rect x="80" y="22" width="8" height="8" fill="#0a0f1e"/><rect x="104" y="22" width="8" height="8" fill="#0a0f1e"/>
<rect x="80" y="80" width="8" height="8" fill="#0a0f1e"/><rect x="92" y="80" width="8" height="8" fill="#0a0f1e"/>
<rect x="104" y="80" width="8" height="8" fill="#0a0f1e"/><rect x="116" y="80" width="8" height="8" fill="#0a0f1e"/>
<rect x="80" y="92" width="8" height="8" fill="#0a0f1e"/><rect x="104" y="92" width="8" height="8" fill="#0a0f1e"/>
<rect x="130" y="80" width="8" height="8" fill="#0a0f1e"/><rect x="154" y="80" width="8" height="8" fill="#0a0f1e"/>
<rect x="130" y="92" width="8" height="8" fill="#0a0f1e"/><rect x="142" y="92" width="8" height="8" fill="#0a0f1e"/>
<rect x="166" y="92" width="8" height="8" fill="#0a0f1e"/><rect x="130" y="104" width="8" height="8" fill="#0a0f1e"/>
<rect x="154" y="104" width="8" height="8" fill="#0a0f1e"/><rect x="80" y="104" width="8" height="8" fill="#0a0f1e"/>
<rect x="92" y="116" width="8" height="8" fill="#0a0f1e"/><rect x="116" y="116" width="8" height="8" fill="#0a0f1e"/>
<rect x="80" y="128" width="8" height="8" fill="#0a0f1e"/><rect x="104" y="128" width="8" height="8" fill="#0a0f1e"/>
<rect x="116" y="128" width="8" height="8" fill="#0a0f1e"/><rect x="80" y="140" width="8" height="8" fill="#0a0f1e"/>
<rect x="92" y="140" width="8" height="8" fill="#0a0f1e"/><rect x="130" y="130" width="8" height="8" fill="#0a0f1e"/>
<rect x="154" y="130" width="8" height="8" fill="#0a0f1e"/><rect x="166" y="130" width="8" height="8" fill="#0a0f1e"/>
<rect x="130" y="154" width="8" height="8" fill="#0a0f1e"/><rect x="142" y="154" width="8" height="8" fill="#0a0f1e"/>
<rect x="166" y="154" width="8" height="8" fill="#0a0f1e"/><rect x="142" y="166" width="8" height="8" fill="#0a0f1e"/>
<rect x="80" y="152" width="8" height="8" fill="#0a0f1e"/><rect x="92" y="164" width="8" height="8" fill="#0a0f1e"/>
<text x="100" y="196" text-anchor="middle" font-family="monospace" font-size="9" fill="#666">$t…</text>
</svg>
SVG;
}
