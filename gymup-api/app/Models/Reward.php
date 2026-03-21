<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Facades\Storage;

class Reward extends Model
{
    use HasFactory;

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

    /**
     * Retorna a URL pública completa da imagem a partir do path relativo salvo no banco.
     * Banco armazena: "rewards/uuid.webp"
     * API retorna:    "http://host/storage/rewards/uuid.webp"
     */
    public function getImageUrlAttribute(?string $value): ?string
    {
        if (!$value) return null;

        // Extrai o path relativo tanto de URLs antigas quanto de paths puros
        // "rewards/uuid.webp"                          → rewards/uuid.webp
        // "http://host/storage/rewards/uuid.webp"      → rewards/uuid.webp
        // "http://host/img/rewards/uuid.webp"          → rewards/uuid.webp
        $path = str_starts_with($value, 'http')
            ? ltrim(preg_replace('#^.+/(storage|img)/#', '', $value), '/')
            : $value;

        // Serve via /img/{path} — passa pelo Laravel (CORS headers aplicados)
        return url('/img/' . $path);
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