<template>
  <q-page padding>
    <!-- <q-toolbar class="bg-primary text-white shadow-2"> -->
    <q-toolbar class="bg-primary text-white shadow-2">
        <q-toolbar-title>Frequently Asked Questions</q-toolbar-title>
    </q-toolbar>

    <q-list bordered>

      <div v-for="faq in faqList" :key="faq.q">
        <q-expansion-item group="FAQgroup" icon="mdi-head-question-outline" :label="faq.q" header-class="text-primary">
          <q-card>
            <q-card-section>
              {{ faq.a }}
            </q-card-section>
          </q-card>
        </q-expansion-item>

        <q-separator />

      </div>
      
    </q-list>

  </q-page>
</template>

<script>
import { SessionStorage } from 'quasar';
//import globalData from 'src/components/GlobalData.js'

var faqList = new Array();

export default {

  data () {
    return {
      faqList: faqList,
    }
  },

  mounted() {
    const xhttp = new XMLHttpRequest();
    xhttp.onload = () => {
      var resultObj = JSON.parse(xhttp.response);
      this.faqList = resultObj.FAQs;
    }
    xhttp.open('POST', 'Services/GetFAQ.aspx', true);
    xhttp.setRequestHeader('SessionKey', SessionStorage.getItem('sessionKey'));
    xhttp.send();

  }
}
</script>
