<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /** Cache de permissões em memória — declarado como propriedade de classe para
     *  evitar que o Eloquent o trate como atributo e tente persisti-lo. */
    private $_permissionsCache = null;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'avatar_url',
        'password',
        'gym_id',
        'active_gym_id',
        'role',
        'points_balance',
        'height',
        'weight',
        'birth_date',
        'weekly_streak',
        'week_goal_completed',
        'current_week_start',
        'current_week_goal',
        'current_streak',
        'best_streak',
        'consistency_bonus_days',
        'last_workout_date',
        'last_schedule_change',
        'invited_at',
        'email_verified_at',
    ];

    protected $casts = [
        'invited_at'             => 'datetime',
        'email_verified_at'      => 'datetime',
        'week_goal_completed'    => 'boolean',
        'current_week_start'     => 'date',
        'last_workout_date'      => 'date',
        'last_schedule_change'   => 'date',
        'consistency_bonus_days' => 'integer',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // ── RBAC: Roles & Permissions ─────────────────────────────────────────────

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'user_roles');
    }

    /**
     * Retorna todas as permissões do usuário (via roles),
     * com cache em memória para evitar N+1 na mesma requisição.
     */
    public function getPermissions(): \Illuminate\Support\Collection
    {
        if ($this->_permissionsCache !== null) {
            return $this->_permissionsCache;
        }

        try {
            $this->_permissionsCache = $this->roles()
                ->with('permissions')
                ->get()
                ->flatMap(fn ($role) => $role->permissions->pluck('name'))
                ->unique()
                ->values();
        } catch (\Exception) {
            // Tabelas RBAC ainda não existem (migração pendente) — permissões vazias.
            $this->_permissionsCache = collect();
        }

        return $this->_permissionsCache;
    }

    public function hasPermission(string $permission): bool
    {
        // super_admin bypass — acesso total
        if ($this->role === 'super_admin') {
            return true;
        }

        return $this->getPermissions()->contains($permission);
    }

    public function hasRole(string $roleName): bool
    {
        // Verifica tanto o campo legado quanto a tabela user_roles
        if ($this->role === $roleName) {
            return true;
        }

        return $this->roles()->where('name', $roleName)->exists();
    }

    // ── Role helpers (legado — mantidos para compatibilidade) ─────────────────

    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    public function isGymAdmin(): bool
    {
        return $this->role === 'gym_admin';
    }

    public function isTrainer(): bool
    {
        return $this->role === 'trainer';
    }

    /**
     * Gym_id efetivo para filtros de contexto.
     * Trainers e gym_admins com active_gym_id definido usam a filial ativa;
     * demais usuários (e super_admin com acesso global) usam gym_id do banco.
     */
    public function activeGymId(): int
    {
        if (! $this->isSuperAdmin() && $this->active_gym_id !== null) {
            return (int) $this->active_gym_id;
        }
        return (int) $this->gym_id;
    }

    public function isNetworkAdmin(): bool
    {
        return $this->role === 'network_admin';
    }

    public function isUser(): bool
    {
        return $this->role === 'user';
    }

    /** Retorna true para qualquer role com acesso ao painel administrativo. */
    public function canAccessAdminPanel(): bool
    {
        return in_array($this->role, ['super_admin', 'network_admin', 'gym_admin', 'trainer'], true);
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    /** Academias às quais este trainer/gym_admin pertence (via trainer_gyms). */
    public function gyms()
    {
        return $this->belongsToMany(Gym::class, 'trainer_gyms', 'trainer_id', 'gym_id')
            ->withPivot('is_primary');
    }

    public function checkins()
    {
        return $this->hasMany(Checkin::class);
    }

    public function pointTransactions()
    {
        return $this->hasMany(PointTransaction::class);
    }

    public function redemptions()
    {
        return $this->hasMany(Redemption::class);
    }

    public function workoutSessions()
    {
        return $this->hasMany(WorkoutSession::class);
    }

    public function goals()
    {
        return $this->hasMany(UserGoal::class);
    }

    public function trainingSchedules()
    {
        return $this->hasMany(UserTrainingSchedule::class);
    }

    // Named userNotifications to avoid collision with Laravel's Notifiable::notifications()
    public function userNotifications()
    {
        return $this->hasMany(UserNotification::class);
    }

    public function sendPasswordResetNotification($token): void
    {
        $url = $this->passwordResetUrl($token);

        $this->notify(new ResetPasswordNotification($url));
    }

    private function passwordResetUrl(string $token): string
    {
        $email = urlencode($this->getEmailForPasswordReset());

        if ($this->role === 'user') {
            $base = rtrim((string) config('app.mobile_frontend_url', 'gymup://reset-password'), '/');

            if (str_contains($base, '://') && ! str_starts_with($base, 'http')) {
                return $base . '?token=' . $token . '&email=' . $email;
            }

            return $base . '/reset-password?token=' . $token . '&email=' . $email;
        }

        $base = rtrim((string) config('app.frontend_url', 'https://admin.gymupapp.com.br'), '/');

        return $base . '/reset-password?token=' . $token . '&email=' . $email;
    }
}
