<template>
<!-- ***************** NOT USED ****************** -->
   <!-- <q-dialog v-model="confirm"> -->
     <div>
  <!-- <q-modal>
    <q-modal-layout> -->
      <q-card>
        <q-toolbar>
          <q-avatar v-if="resultText === 'Error' || resultText === 'System Error'">
            <!-- <img src="https://cdn.quasar.dev/logo-v2/svg/logo.svg"> -->
            <q-img src="~assets\Error.svg" width="64px" height="64px"></q-img>
          </q-avatar>
          <q-avatar v-if="resultText === 'Warning'">
            <q-img src="~assets\Warning.svg" width="64px" height="64px"></q-img>
          </q-avatar>
          <q-avatar v-if="resultText === 'Information'">
            <q-img src="~assets\Information.svg" width="64px" height="64px"></q-img>
          </q-avatar>

          <q-toolbar-title class="text-orange-12">{{ resultTitle }}</q-toolbar-title>

          <q-btn flat round dense icon="mdi-close" v-close-popup />
        </q-toolbar>

        <q-card-section>
          {{ resultMsg }}
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="OK" color="orange-9" v-close-popup />
        </q-card-actions>
      </q-card>

  <!--  </q-modal-layout>

  </q-modal> -->

     </div>



</template>

<script>
//import { ref } from 'vue'
import { SessionStorage } from 'quasar'

export default {
  // name: 'ComponentName',
  setup () {
    var resultText = SessionStorage.getItem('ResultText');    //  OK, Error, etc.
    var resultMsg = SessionStorage.getItem('ResultMsg');;
    var resultTitle = SessionStorage.getItem('ResultTitle');
    return {
      //confirm: ref(false),
      resultText,
      resultTitle,
      resultMsg
    }
  }
}
</script>
