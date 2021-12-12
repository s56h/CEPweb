<template>
  <q-layout view="hHh Lpr lFf">
    <q-header elevated>   <!--   Header   -->
      <q-toolbar>
        <q-btn flat dense round icon="mdi-menu"
          aria-label="Menu"
          @click="toggleLeftDrawer"
        />

        <q-toolbar-title>
          CCC Installer
        </q-toolbar-title>

        <q-btn color="orange" flat round icon="mdi-logout" @click="confirm = true"></q-btn>
      </q-toolbar>
    </q-header>

    <q-footer>   <!--   Footer   -->
      <div class="bg-white q-pa-xs row">
        <span class="col-7 q-pt-sm">
          <q-chip size="md" icon="mdi-face-outline" color="orange-9" text-color="white">
            {{installerName}}
          </q-chip>
        </span>
        <span class="col-5">
          <q-img no-spinner fit="scale-down" height="50px" src="~assets/Commercial-flooring-sydney.png" />
        </span>
      </div>
      <div>
        <span v-if="testEnvironment" class="bg-yellow q-pa-sm row text-bold text-blue">Test Environment</span>
        <span class="float-right text-caption text-orange-4">v{{appVersion}}</span>
      </div>
    </q-footer>

   <!--   Drawer   -->
    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
    >
      <q-list bordered>
        <q-item-label header >
        <span class="text-bold text-orange-9">Select</span>
        </q-item-label>

        <SlideMenu
          v-for="link in menuLinks"
          :key="link.title"
          v-bind="link"
        />
      </q-list>
    </q-drawer>

    <!--   Dialog   -->
    <q-dialog v-model="confirm" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-icon name="mdi-alert-octagon" class="text-orange-9" style="font-size:4em" />
          <span class="q-ml-sm">Are you sure you are finished?</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Yes" color="warning"  to="/Login" />
          <q-btn flat label="No" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
import { version } from '../../package';
import SlideMenu from 'src/components/SlideMenu.vue';
import { SessionStorage } from 'quasar';

//import globalData from 'src/components/GlobalData.js'

const menuList = [
  {
    title: 'Checklist',
    icon: 'mdi-format-list-checks',
    link: '/app/CheckList'
  },
  {
    title: 'Contact CCC',
    icon: 'mdi-account-box-outline',
    link: '/app/Contact'
  },
  {
    title: 'FAQs',
    icon: 'mdi-help',
    link: '/app/FAQ'
  }
];

export default defineComponent({
  name: 'MainLayout',

  components: {
    SlideMenu
  },

  setup () {
    const leftDrawerOpen = ref(false)
    const installerName = SessionStorage.getItem('installerName');
    const testStatus = (SessionStorage.getItem('environment') == 'test') ? true : false;

    return {
      appVersion: version,
      menuLinks: menuList,
      confirm: ref(false),
      installerName: installerName,
      testEnvironment: testStatus,
      leftDrawerOpen,
      toggleLeftDrawer () {
        leftDrawerOpen.value = !leftDrawerOpen.value
      }
    }
  }
})
</script>
