<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return view('welcome');
});

/*
 * Serve arquivos de storage com headers CORS corretos.
 * Necessário para Flutter Web (CanvasKit) que usa fetch() cross-origin.
 * Acesso: GET /img/rewards/uuid.webp
 */
Route::get('/img/{path}', function (string $path) {
    if (!Storage::disk('public')->exists($path)) {
        abort(404);
    }

    $fullPath = Storage::disk('public')->path($path);
    $mimeType = mime_content_type($fullPath) ?: 'application/octet-stream';

    return response()->file($fullPath, [
        'Content-Type'                => $mimeType,
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control'               => 'public, max-age=31536000',
    ]);
})->where('path', '.*');
