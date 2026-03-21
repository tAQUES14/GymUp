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
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('../views/DashboardView.vue'),
          meta: { title: 'Dashboard', icon: 'dashboard' },
        },
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
        {
          path: 'achievements',
          name: 'achievements',
          component: () => import('../views/AchievementsView.vue'),
          meta: { title: 'Conquistas' },
        },
        {
          path: 'ranking',
          name: 'ranking',
          component: () => import('../views/RankingView.vue'),
          meta: { title: 'Ranking' },
        },
        {
          path: 'rewards',
          name: 'rewards',
          component: () => import('../views/RewardsView.vue'),
          meta: { title: 'Recompensas' },
        },
        {
          path: 'redemptions',
          name: 'redemptions',
          component: () => import('../views/RedemptionsView.vue'),
          meta: { title: 'Resgates' },
        },
        {
          path: 'gyms',
          name: 'gyms',
          component: () => import('../views/PlaceholderView.vue'),
          props: { page: 'Academias', icon: '🏢', description: 'Gerencie as academias da plataforma.' },
          meta: { title: 'Academias', superAdminOnly: true },
        },
        {
          path: 'reports',
          name: 'reports',
          component: () => import('../views/ReportsView.vue'),
          meta: { title: 'Relatórios', gymAdminOrAbove: true },
        },
        {
          path: 'settings',
          name: 'settings',
          component: () => import('../views/SettingsView.vue'),
          meta: { title: 'Configurações', gymAdminOrAbove: true },
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

  next()
})

export default router
