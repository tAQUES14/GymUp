<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Services\ImageService;
use App\Services\StreakService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class ProfileController extends Controller
{
    private const FALLBACK_PUBLIC_STORAGE_BASE_URL = 'https://s3.us-west-004.backblazeb2.com/gymup-storage';

    public function __construct(private ImageService $images) {}

    public function show(Request $request, StreakService $streakService)
    {
        $user = $request->user()->load('gym:id,name');

        $totalCheckins = Checkin::where('user_id', $user->id)->count();

        $currentStreak = $streakService->getStreakState($user)['streak'];

        return response()->json([
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'phone'          => Schema::hasColumn('users', 'phone') ? $user->phone : null,
            'avatar_url'     => Schema::hasColumn('users', 'avatar_url') ? $this->avatarUrl($user->avatar_url) : null,
            'role'           => $user->role,
            'points_balance' => (int) $user->points_balance,
            'total_checkins' => $totalCheckins,
            'current_streak' => $currentStreak,
            'weight'         => Schema::hasColumn('users', 'weight') ? $user->weight : null,
            'height'         => Schema::hasColumn('users', 'height') ? $user->height : null,
            'gym'            => $user->gym ? [
                'id'   => $user->gym->id,
                'name' => $user->gym->name,
            ] : null,
        ]);
    }

    /**
     * PUT /api/profile
     *
     * Update user profile fields with proper validation.
     */
    public function update(Request $request)
    {
        $request->validate([
            'name'   => 'nullable|string|max:255',
            'phone'  => 'nullable|string|max:30',
            'weight' => 'nullable|numeric|min:30|max:300',
            'height' => 'nullable|numeric|min:100|max:250',
        ]);

        $user = $request->user();

        $fields = collect(['name', 'phone', 'weight', 'height'])
            ->filter(fn ($field) => Schema::hasColumn('users', $field))
            ->values()
            ->all();

        $user->update($request->only($fields));
        $user->refresh();

        return response()->json([
            'message' => 'Perfil atualizado com sucesso.',
            'user'    => [
                'id'         => $user->id,
                'name'       => $user->name,
                'phone'      => $user->phone,
                'avatar_url' => $this->avatarUrl($user->avatar_url),
                'weight'     => $user->weight,
                'height'     => $user->height,
            ],
        ]);
    }

    public function updateAvatar(Request $request)
    {
        if (! Schema::hasColumn('users', 'avatar_url')) {
            return response()->json([
                'message' => 'A coluna avatar_url ainda nao existe na tabela users. Execute as migrations.',
            ], 409);
        }

        $request->validate([
            'avatar' => 'required|image|max:4096',
        ]);

        $user = $request->user();

        try {
            $path = $this->images->store(
                $request->file('avatar'),
                'avatars',
                maxDimension: 512,
                maxSizeBytes: 180_000,
                qualityStart: 82
            );
        } catch (\Throwable) {
            return response()->json([
                'message' => 'Nao foi possivel enviar a foto para o storage.',
            ], 422);
        }

        if ($user->avatar_url) {
            $this->images->delete($user->avatar_url);
        }

        $user->update(['avatar_url' => $path]);

        return response()->json([
            'message'    => 'Foto atualizada com sucesso.',
            'avatar_url' => $this->avatarUrl($path),
        ]);
    }

    private function avatarUrl(?string $value): ?string
    {
        if (! $value) {
            return null;
        }

        if (str_starts_with($value, 'http') && ! str_contains($value, 'gymup-api.onrender.com/storage')) {
            return $value;
        }

        $path = $this->normalizeAvatarPath($value);
        if (! $path) {
            return null;
        }

        $encoded = implode('/', array_map('rawurlencode', explode('/', $path)));
        return rtrim($this->publicStorageBaseUrl(), '/') . '/' . $encoded;
    }

    private function normalizeAvatarPath(string $value): string
    {
        if (! str_starts_with($value, 'http')) {
            return ltrim($value, '/');
        }

        $path = rawurldecode(parse_url($value, PHP_URL_PATH) ?: '');

        if (preg_match('#/(?:storage|img)/(.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        if (preg_match('#/(avatars/.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        return ltrim($path, '/');
    }

    private function publicStorageBaseUrl(): string
    {
        $publicDisk = config('filesystems.disks.public', []);
        $publicUrl = env('PUBLIC_DISK_URL');

        if (! $publicUrl && ($publicDisk['driver'] ?? null) === 's3') {
            $endpoint = $publicDisk['endpoint'] ?? null;
            $bucket = $publicDisk['bucket'] ?? null;

            if ($endpoint && $bucket) {
                $publicUrl = rtrim($endpoint, '/') . '/' . $bucket;
            }
        }

        $publicUrl ??= $publicDisk['url'] ?? null;

        if (! $publicUrl || str_contains($publicUrl, 'gymup-api.onrender.com/storage')) {
            return self::FALLBACK_PUBLIC_STORAGE_BASE_URL;
        }

        return $publicUrl;
    }
}
