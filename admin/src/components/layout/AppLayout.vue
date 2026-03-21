<template>
  <div class="min-h-screen bg-slate-50">
    <AppSidebar />
    <AppHeader />

    <main class="ml-64 pt-16">
      <div class="p-8">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<script setup>
import { RouterView } from 'vue-router'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'
</script>
