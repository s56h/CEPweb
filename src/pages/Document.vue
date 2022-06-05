<template>
  <q-page padding>
    <div class="q-pa-md q-gutter-md">
      <q-card class="q-ma-none" transition-show="slide-left">
        <q-item class="bg-orange-3">
          <q-item-section>
            <q-item-label>{{ documentName }}</q-item-label>
            <q-item-label caption>{{ documentStatus }}</q-item-label>
          </q-item-section>

          <q-item-section side>
            <q-btn size="12px" flat dense round icon="mdi-close" @click="showListTabs"> 
            </q-btn>
          </q-item-section>
        </q-item>

        <img v-show="this.isImage" id="downloadedImage" >
        <div v-show="this.isPdf">
          <div class="q-pa-md q-gutter-sm" style="height: 600px;">
            <q-pdfviewer
              type="html5"
              :src="documentSource"
              error-string="This browser cannot view pdfs. Download the pdf to view it"
            />
          </div>
        </div>

      </q-card>
    </div>

    <q-dialog v-model="userMessage" persistent> <!-- should be a component -->
      <q-card>
        <q-toolbar>

          <q-icon v-if="resultType === 'Error' || resultType === 'System Error'" name="mdi-alert-octagon" class="text-red" style="font-size:4em" />
          <q-icon v-if="resultType === 'Warning'" name="mdi-alert-circle-outline" class="text-orange-9" style="font-size:4em" />
          <q-icon v-if="resultType === 'Information'" name="mdi-information-outline" class="text-orange-5" style="font-size:4em" />

          <q-toolbar-title class="text-orange-12">{{ resultTitle }}</q-toolbar-title>
          <q-btn flat round dense icon="mdi-close" v-close-popup />

        </q-toolbar>

        <q-card-section class="row items-center">
          <span class="q-ml-sm">{{ resultMsg }}</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn v-if="sessionTimeout" flat label="OK" color="orange-9" to="/Login" />
          <q-btn v-else flat label="OK" color="orange-9" v-close-popup />
        </q-card-actions>

      </q-card>
    </q-dialog>

  </q-page>
</template>

<script>
//import { SessionStorage } from 'quasar';

export default {

  data () {
    return {
      isImage: false,
      isPdf: false,
      resultMsg: '',
      resultType: '',
      resultTitle: '',
      userMessage: false,
      sessionTimeout: false,
      documentSource: '',
      serverSession: this.$sessionKey,
      documentName: this.$documentName,
      documentStatus: this.$documentStatus
    }
  },

  mounted () {
    //
    //    Download the selected document
    //

    const xhttp = new XMLHttpRequest();
    xhttp.onload = () => {
      if (xhttp.status != 200) {
        this.resultMsg = 'System error (code ' + xhttp.status + ')';
        this.resultType = 'System Error';
        this.resultTitle = 'System Error';
        this.userMessage = true;
        return;
      }
      var resultObj = JSON.parse(xhttp.response);
      //console.log(resultObj);
      var resultCode = parseInt(resultObj.resultCode);
      this.resultMsg = resultObj.resultMsg;
      this.resultType = resultObj.resultType;
      this.resultTitle = resultObj.resultTitle;
      this.documentSource = resultObj.documentSource;
      //console.log('Result: ['+resultCode+'], ['+this.resultMsg+'], ['+this.resultType+'], ['+this.resultTitle+']');

      if (resultCode != 0) {
        if (resultCode == 30) {
          this.sessionTimeout = true;
        }
        this.userMessage = true;
      }
      else {
        //console.log('setting image');
        //console.log(decodeURI(this.documentSource));
        var fileExt = this.documentSource.substr(this.documentSource.lastIndexOf('.') + 1);
        if (fileExt == 'pdf') {
          //console.log('showing pdf');
          this.isPdf = true;
          this.isImage = false;
          //console.log(this.documentSource);
        }
        else {
          //console.log('showing image');
          this.isPdf = false;
          this.isImage = true;
          document.getElementById('downloadedImage').src = this.documentSource;
        }
      }
    }

    xhttp.open('POST', 'Services/GetDocument.aspx', true);
    xhttp.setRequestHeader('Content-Type','multipart/form-data');
    xhttp.setRequestHeader('InstallerId', this.$installerId);
    xhttp.setRequestHeader('InstallerCompanyId', this.$installerCompanyId);
    xhttp.setRequestHeader('DocumentId', this.$checklistId);
    xhttp.setRequestHeader('CheckType', this.$checkType);
    xhttp.setRequestHeader('SessionKey', this.$sessionKey);
    xhttp.send();

  },

  methods: {

      showListTabs () {
        window.history.length > 1 ? this.$router.go(-1) : this.$router.push('/app/Main'); // ******************* pop?
      },

  }
  
}

</script>
