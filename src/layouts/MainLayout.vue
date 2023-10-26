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

    <q-page-container>   <!--   Page container   -->
      <router-view />
    </q-page-container>

    <q-footer>   <!--   Footer   -->
      <div class="bg-white q-pa-xs row fit justify-between items-center">
        <div class="q-pt-sm col">
          <q-chip size="md" icon="mdi-face-outline" color="orange-9" text-color="white">
            {{installerName}}
          </q-chip>
        </div>
        <div class="col">
        <!-- <div class="q-pt-sm col">
        <div class="q-pt-sm col float-right" style="display: flex; justify-content: flex-end"> -->
          <!-- image right -->
          <div style="width: 175px; margin-left: auto; margin-right: 0px">
            <q-img fit="scale-down" height="50px" src="~assets/Commercial-flooring-sydney.png" />
          </div>
        </div>
      </div>
      <div class="fit row justify-between items-center text-orange-4">
        <div v-if="testEnvironment" class="text-subtitle2 text-bold q-pl-sm">
          Test Environment
        </div>
        <div class="float-right text-caption">
          v{{ appVersion }}
        </div>
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
          <q-btn flat label="Yes" color="warning"  @click="doLogout" />   <!-- ############## clear routes ################### -->
          <q-btn flat label="No" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-layout>
</template>

<script>
import { defineComponent, ref } from 'vue';
//import { version } from '../../package';
import { SessionStorage } from 'quasar';
import SlideMenu from 'src/components/SlideMenu.vue';

//import globalData from 'src/components/GlobalData.js'

const menuList = [
  /* v1.2
  {
    title: 'Submit Invoice',
    icon: 'mdi-currency-usd',
    link: '/app/home/submitinvoice'
  },
  {
    title: 'Invoices',
    icon: 'mdi-cash-multiple',
    link: '/app/home/invoicelist'
  },
  {
    title: 'Checklist',
    icon: 'mdi-format-list-checks',
    link: '/app/home/checklist'
  },
  */
  {
    title: 'Checklist',
    icon: 'mdi-format-list-checks',
    link: '/app/home'
  },
  /* v1.2
  {
    title: 'My signature',
    icon: 'mdi-signature-freehand',
    link: '/app/SignPad'
  }, */
  {
    title: 'Contact CCC',
    icon: 'mdi-account-box-outline',
    link: '/app/contact'
  },
  {
    title: 'FAQs',
    icon: 'mdi-help',
    link: '/app/faq'
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
      appVersion: SessionStorage.getItem('appVersion'),
      menuLinks: menuList,
      confirm: ref(false),
      installerName: installerName,
      testEnvironment: testStatus,
      leftDrawerOpen,
      toggleLeftDrawer () {
        leftDrawerOpen.value = !leftDrawerOpen.value
      }
    }
  },

  
  methods: {

    doLogout () {
      //    Clear session storage
      //SessionStorage.set('loginState',false);
      var userEmail = SessionStorage.getItem('userEmail');
      SessionStorage.clear();
      SessionStorage.set('userEmail',userEmail);

      this.$router.replace('/login');
    }

  }

})
</script>
