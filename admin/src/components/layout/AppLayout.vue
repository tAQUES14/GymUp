<template>
  <div class="min-h-screen bg-slate-50">
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-40 bg-slate-950/55 backdrop-blur-sm lg:hidden"
      aria-hidden="true"
      @click="sidebarOpen = false"
    />
    <AppSidebar :open="sidebarOpen" @close="sidebarOpen = false" />
    <AppHeader @toggle-sidebar="sidebarOpen = !sidebarOpen" />

    <main class="min-w-0 pt-16 lg:ml-64">
      <div class="p-4 sm:p-6 lg:p-8">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { RouterView } from 'vue-router'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'

const sidebarOpen = ref(false)
</script>
