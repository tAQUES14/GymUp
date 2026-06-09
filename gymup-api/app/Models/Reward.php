<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reward extends Model
{
    use HasFactory;

    private const FALLBACK_PUBLIC_STORAGE_BASE_URL = 'https://s3.us-west-004.backblazeb2.com/gymup-storage';

    protected $fillable = [
        'gym_id',
        'name',
        'description',
        'image_url',
        'category',
        'points_cost',
        'stock',
        'discount_percent',
        'active',
    ];

    protected $casts = [
        'active' => 'boolean',
    ];

    public function getImageUrlAttribute(?string $value): ?string
    {
        if (!$value) {
            return null;
        }

        $path = self::normalizeImagePath($value);

        if (!$path) {
            return null;
        }

        $encoded = implode('/', array_map('rawurlencode', explode('/', $path)));

        return rtrim(self::publicStorageBaseUrl(), '/') . '/' . $encoded;
    }

    public static function normalizeImagePath(string $value): string
    {
        if (!str_starts_with($value, 'http')) {
            return ltrim($value, '/');
        }

        $path = rawurldecode(parse_url($value, PHP_URL_PATH) ?: '');

        if (preg_match('#/(?:storage|img)/(.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        if (preg_match('#/(rewards/.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        return ltrim($path, '/');
    }

    private static function publicStorageBaseUrl(): string
    {
        $publicDisk = config('filesystems.disks.public', []);
        $publicUrl = env('PUBLIC_DISK_URL');

        if (!$publicUrl && ($publicDisk['driver'] ?? null) === 's3') {
            $endpoint = $publicDisk['endpoint'] ?? null;
            $bucket = $publicDisk['bucket'] ?? null;

            if ($endpoint && $bucket) {
                $publicUrl = rtrim($endpoint, '/') . '/' . $bucket;
            }
        }

        $publicUrl ??= $publicDisk['url'] ?? null;

        if (!$publicUrl || str_contains($publicUrl, 'gymup-api.onrender.com/storage')) {
            return self::FALLBACK_PUBLIC_STORAGE_BASE_URL;
        }

        return $publicUrl;
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    public function redemptions()
    {
        return $this->hasMany(Redemption::class);
    }
}
