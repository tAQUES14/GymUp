import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { guest: true },
    },
    {
      path: '/',
      component: () => import('../components/layout/AppLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          redirect: '/dashboard',
        },
        // ── Dashboard ────────────────────────────────────────────────────────
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('../views/DashboardView.vue'),
          meta: { title: 'Dashboard', icon: 'dashboard' },
        },
        // ── Treinos ──────────────────────────────────────────────────────────
        {
          path: 'workouts',
          name: 'workouts',
          component: () => import('../views/WorkoutsView.vue'),
          meta: { title: 'Treinos' },
        },
        {
          path: 'workouts/:id',
          name: 'workout-detail',
          component: () => import('../views/WorkoutDetailView.vue'),
          meta: { title: 'Detalhe do Treino' },
        },
        // ── Alunos ───────────────────────────────────────────────────────────
        {
          path: 'users',
          name: 'users',
          component: () => import('../views/UsersView.vue'),
          meta: { title: 'Alunos' },
        },
        {
          path: 'users/:id',
          name: 'user-detail',
          component: () => import('../views/UserDetailView.vue'),
          meta: { title: 'Perfil do Aluno' },
        },
        // ── Planos de Treino ─────────────────────────────────────────────────
        {
          path: 'workout-plans',
          name: 'workout-plans',
          component: () => import('../views/WorkoutPlansView.vue'),
          meta: { title: 'Planos de Treino' },
        },
        {
          path: 'workout-plans/:id',
          name: 'workout-plan-detail',
          component: () => import('../views/WorkoutPlanDetailView.vue'),
          meta: { title: 'Detalhe do Plano' },
        },
        // ── Exercícios ───────────────────────────────────────────────────────
        {
          path: 'exercises',
          name: 'exercises',
          component: () => import('../views/ExercisesView.vue'),
          meta: { title: 'Exercícios' },
        },
        {
          path: 'exercises/gif-mapping',
          name: 'exercise-gif-mapping',
          component: () => import('../views/ExerciseGifMappingView.vue'),
          meta: { title: 'Mapeamento de GIFs' },
        },
        // ── Desafios ─────────────────────────────────────────────────────────
        {
          path: 'challenges',
          name: 'challenges',
          component: () => import('../views/ChallengesView.vue'),
          meta: { title: 'Desafios' },
        },
        {
          path: 'challenges/:id',
          name: 'challenge-detail',
          component: () => import('../views/ChallengeDetailView.vue'),
          meta: { title: 'Detalhe do Desafio' },
        },
        // ── Conquistas ───────────────────────────────────────────────────────
        {
          path: 'achievements',
          name: 'achievements',
          component: () => import('../views/AchievementsView.vue'),
          meta: { title: 'Conquistas' },
        },
        // ── Ranking ──────────────────────────────────────────────────────────
        {
          path: 'ranking',
          name: 'ranking',
          component: () => import('../views/RankingView.vue'),
          meta: { title: 'Ranking' },
        },
        // ── Recompensas ──────────────────────────────────────────────────────
        {
          path: 'rewards',
          name: 'rewards',
          component: () => import('../views/RewardsView.vue'),
          meta: { title: 'Recompensas' },
        },
        // ── Resgates ─────────────────────────────────────────────────────────
        {
          path: 'redemptions',
          name: 'redemptions',
          component: () => import('../views/RedemptionsView.vue'),
          meta: { title: 'Resgates' },
        },
        // ── Convidar Alunos (gym_admin+) ────────────────────────────────────
        {
          path: 'invite',
          name: 'invite',
          component: () => import('../views/InviteStudentsView.vue'),
          meta: { title: 'Convidar Alunos', gymAdminOrAbove: true },
        },
        // ── Check-in & QR Code (gym_admin+) ─────────────────────────────────
        {
          path: 'checkin',
          name: 'checkin',
          component: () => import('../views/CheckinView.vue'),
          meta: { title: 'Check-in & QR Code', gymAdminOrAbove: true },
        },
        // ── Equipe e Acessos (gym_admin+) ────────────────────────────────────
        {
          path: 'team',
          name: 'team',
          component: () => import('../views/TeamView.vue'),
          meta: { title: 'Equipe e Acessos', gymAdminOrAbove: true },
        },
        // ── Roles e Permissões técnicos (gym_admin+, mantido para compatibilidade) ─
        {
          path: 'roles',
          name: 'roles',
          component: () => import('../views/RolesView.vue'),
          meta: { title: 'Permissões', gymAdminOrAbove: true },
        },
        // ── Academias (super_admin) ──────────────────────────────────────────
        {
          path: 'gyms',
          name: 'gyms',
          component: () => import('../views/SuperGymsView.vue'),
          meta: { title: 'Academias', superAdminOnly: true },
        },
        // ── Relatórios (gym_admin+) ──────────────────────────────────────────
        {
          path: 'reports',
          name: 'reports',
          component: () => import('../views/ReportsView.vue'),
          meta: { title: 'Relatórios', gymAdminOrAbove: true },
        },
        // ── Configurações (gym_admin+) ───────────────────────────────────────
        {
          path: 'settings',
          name: 'settings',
          component: () => import('../views/SettingsView.vue'),
          meta: { title: 'Configurações', gymAdminOrAbove: true },
        },
        // ── Painel da Rede (network_admin) ───────────────────────────────────
        {
          path: 'network/dashboard',
          name: 'network-dashboard',
          component: () => import('../views/NetworkDashboardView.vue'),
          meta: { title: 'Painel da Rede', networkAdminOnly: true },
        },
        {
          path: 'network/gyms',
          name: 'network-gyms',
          component: () => import('../views/NetworkGymsListView.vue'),
          meta: { title: 'Filiais da Rede', networkAdminOnly: true },
        },
        {
          path: 'network/gyms/new',
          name: 'network-gym-new',
          component: () => import('../views/NetworkGymFormView.vue'),
          meta: { title: 'Nova Filial', networkAdminOnly: true },
        },
        {
          path: 'network/gyms/:id/edit',
          name: 'network-gym-edit',
          component: () => import('../views/NetworkGymFormView.vue'),
          meta: { title: 'Editar Filial', networkAdminOnly: true },
        },
        {
          path: 'network/trainers',
          name: 'network-trainers',
          component: () => import('../views/NetworkTrainersView.vue'),
          meta: { title: 'Trainers da Rede', networkAdminOnly: true },
        },
        // ── Redes (super_admin) ──────────────────────────────────────────────
        {
          path: 'chains',
          name: 'chains',
          component: () => import('../views/ChainsListView.vue'),
          meta: { title: 'Redes', superAdminOnly: true },
        },
        {
          path: 'chains/new',
          name: 'chain-new',
          component: () => import('../views/ChainFormView.vue'),
          meta: { title: 'Nova Rede', superAdminOnly: true },
        },
        {
          path: 'chains/:id',
          name: 'chain-detail',
          component: () => import('../views/ChainDetailView.vue'),
          meta: { title: 'Detalhes da Rede', superAdminOnly: true },
        },
        {
          path: 'chains/:id/edit',
          name: 'chain-edit',
          component: () => import('../views/ChainFormView.vue'),
          meta: { title: 'Editar Rede', superAdminOnly: true },
        },
      ],
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/dashboard',
    },
  ],
})

router.beforeEach((to, _from, next) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return next('/login')
  }
  if (to.meta.guest && auth.isAuthenticated) {
    return next('/dashboard')
  }
  if (to.meta.superAdminOnly && !auth.isSuperAdmin) {
    return next('/dashboard')
  }
  if (to.meta.gymAdminOrAbove && !auth.isSuperAdmin && !auth.isGymAdmin) {
    return next('/dashboard')
  }
  if (to.meta.networkAdminOnly && auth.user?.role !== 'network_admin') {
    return next('/dashboard')
  }

  next()
})

export default router
