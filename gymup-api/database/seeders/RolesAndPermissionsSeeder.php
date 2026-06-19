<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Catálogo completo de permissões do sistema.
     * Nunca hardcode lógica de acesso: sempre derive de hasPermission().
     */
    private array $permissions = [
        // Usuários / Alunos
        'view_users'      => 'Visualizar alunos',
        'edit_users'      => 'Editar dados de alunos',
        'delete_users'    => 'Remover alunos',
        'adjust_points'   => 'Ajustar pontos de alunos',

        // Treinos
        'view_workouts'        => 'Visualizar treinos',
        'manage_workouts'      => 'Criar e editar treinos',
        'assign_workouts'      => 'Atribuir treinos a alunos',
        'manage_workout_plans' => 'Gerenciar planos de treino',

        // Exercícios
        'manage_exercises' => 'Gerenciar exercícios',

        // Desafios
        'manage_challenges' => 'Gerenciar desafios',

        // Conquistas
        'manage_achievements' => 'Gerenciar conquistas',

        // Recompensas e resgates
        'manage_rewards'     => 'Gerenciar recompensas',
        'manage_redemptions' => 'Aprovar e rejeitar resgates',

        // Ranking e relatórios
        'view_ranking'  => 'Visualizar ranking',
        'view_reports'  => 'Visualizar relatórios e métricas',

        // Roles, configurações e academias
        'manage_roles'    => 'Criar e editar roles da academia',
        'manage_settings' => 'Alterar configurações do sistema',
        'manage_gyms'     => 'Gerenciar academias (super_admin)',
    ];

    // ── Permissões por perfil ─────────────────────────────────────────────────

    /**
     * gym_admin: acesso total dentro da própria academia.
     * NÃO inclui manage_gyms (gestão global de academias — super_admin).
     */
    private array $gymAdminPermissions = [
        'view_users',
        'edit_users',
        'delete_users',
        'adjust_points',
        'view_workouts',
        'manage_workouts',
        'assign_workouts',
        'manage_workout_plans',
        'manage_exercises',
        'manage_challenges',
        'manage_achievements',
        'manage_rewards',
        'manage_redemptions',  // gym_admin aprova resgates da academia
        'view_ranking',
        'view_reports',
        'manage_roles',
        'manage_settings',     // configurações da academia (gym schedule etc.)
    ];

    /**
     * trainer: acesso focado em gestão de treinos e visualização de alunos.
     * Não gerencia recompensas, resgates nem configurações.
     */
    private array $trainerPermissions = [
        'view_users',
        'view_workouts',
        'manage_workouts',
        'assign_workouts',
        'manage_workout_plans',
        'view_ranking',
    ];

    public function run(): void
    {
        // 1. Criar / atualizar todas as permissões
        foreach ($this->permissions as $name => $description) {
            Permission::firstOrCreate(
                ['name' => $name],
                ['description' => $description]
            );
        }

        // 2. super_admin (global, gym_id = null)
        //    hasPermission() tem bypass total para super_admin, mas criamos
        //    o role com todas as permissões para representação formal no sistema.
        $superAdminRole = Role::firstOrCreate(['name' => 'super_admin', 'gym_id' => null]);
        $superAdminRole->permissions()->sync(Permission::pluck('id'));

        // 3. gym_admin (template global — gym_id = null)
        //    Cada academia pode customizar ou criar seu próprio gym_admin.
        $gymAdminRole = Role::firstOrCreate(['name' => 'gym_admin', 'gym_id' => null]);
        $gymAdminRole->permissions()->sync(
            Permission::whereIn('name', $this->gymAdminPermissions)->pluck('id')
        );

        // 4. trainer (template global)
        $trainerRole = Role::firstOrCreate(['name' => 'trainer', 'gym_id' => null]);
        $trainerRole->permissions()->sync(
            Permission::whereIn('name', $this->trainerPermissions)->pluck('id')
        );

        // 5. Vincular usuários existentes aos roles corretos (idempotente)
        $this->assignExistingUsers($superAdminRole, $gymAdminRole, $trainerRole);

        $this->command?->info('✅ Roles e permissões atualizados com sucesso.');
        $this->command?->table(
            ['Role', 'Permissões'],
            [
                ['super_admin', count(Permission::pluck('id')) . ' (todas)'],
                ['gym_admin',   count($this->gymAdminPermissions)],
                ['trainer',     count($this->trainerPermissions)],
            ]
        );
    }

    private function assignExistingUsers(Role $superAdmin, Role $gymAdmin, Role $trainer): void
    {
        User::where('role', 'super_admin')->each(
            fn (User $u) => $u->roles()->syncWithoutDetaching([$superAdmin->id])
        );
        User::where('role', 'gym_admin')->each(
            fn (User $u) => $u->roles()->syncWithoutDetaching([$gymAdmin->id])
        );
        User::where('role', 'trainer')->each(
            fn (User $u) => $u->roles()->syncWithoutDetaching([$trainer->id])
        );
    }
}
