<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Role extends Model
{
    protected $fillable = ['name', 'gym_id'];

    // ── Relationships ────────────────────────────────────────────────────────

    public function gym(): BelongsTo
    {
        return $this->belongsTo(Gym::class);
    }

    public function permissions(): BelongsToMany
    {
        return $this->belongsToMany(Permission::class, 'role_permissions');
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_roles');
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /** Role global = não pertence a nenhuma academia */
    public function isGlobal(): bool
    {
        return is_null($this->gym_id);
    }
}
