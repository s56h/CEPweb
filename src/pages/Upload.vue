<template>
  <q-page padding>
    <q-form>

      <q-card class="bg-orange-2">
        <q-card-section class="q-pa-xs text-grey-9 bg-orange-2">
          <div class="text-h6 q-mb-xs">{{ documentName }}</div>
          <div  v-if="dateNeeded && !filePickReady" class="text-subtitle2">Select the expiry date ...</div>
          <div v-if="dateNeeded && filePickReady" class="fit row justify-between items-center">
            <div class="text-subtitle2">
              {{ dateSelection }}
            </div>
            <div class="bg-orange-4">
              <q-btn icon="mdi-backspace" color="orange" class="" @click="resetDate()" />
            </div>
          </div>
        </q-card-section>
        <q-separator color="orange" inset />
        <q-card-section class="q-pa-xs">
            <q-date v-if="dateNeeded && !filePickReady"
              v-model="expiryDate"
              class="full-width"
              minimal
              color="orange-3"
              text-color="grey-9"
              bordered
              :navigation-min-year-month="minDate"
              :options="date => date > todayDate"
              @update:model-value="expiryChange()"
            />
        </q-card-section>
        <q-card-section class="q-pa-xs bg-orange-2">
          <div  v-if="filePickReady && !uploadReady" class="text-subtitle2 text-grey-9">Select your document (use '+' below):</div>
          <q-uploader v-if="filePickReady"
            name="Quploader"
            ref="qUploaderRef"
            url="Services/StoreDocument.aspx"
            class="full-width"
            style="max-width: 500px"
            max-file-size="10240000"
            @added="fileAdded" 
            @removed="fileRemoved"
            @finish="showUploadResult"
            @rejected="handleReject" 
            color="orange"
            hide-upload-btn
            text-color="grey-9"
            maxfiles="1"
            accept=".pdf, .gif, .jpg, .docx, .png"
            flat
            bordered
          />
        </q-card-section>
        <q-card-section class="q-pa-xs text-grey-9 bg-orange-2">
          <q-btn v-if="uploadReady" align="between" class="full-width bg-orange" label="Upload Now" icon="mdi-cloud-upload" @click="uploadFile()" />
        </q-card-section>

      </q-card>

    </q-form>

    <q-dialog v-model="userMessage" persistent>
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

import { ref } from 'vue'
import { useQuasar } from 'quasar';
import { SessionStorage } from 'quasar';

var dateToday = new Date();
const day = dateToday.toLocaleString('default', { day: '2-digit' });
const month = dateToday.toLocaleString('default', { month: '2-digit' });
const year = dateToday.toLocaleString('default', { year: 'numeric' });
var minDate = year + '/' + month;
var todayDate = minDate + '/' + day;
//var dateSelection = '';

export default {
  setup () {
    const $q = useQuasar();

    return {

      onFailed () {
          this.resultTitle = 'Unexpected Error';
          this.resultMsg = 'An unexpected error occured while uploading the file. Please try again or contact CCC.';
          this.resultType = 'System Error';
      },

      showUploadNote (text, colour, milliseconds) {
        $q.notify({
          message: text,
          color: colour,
          timeout: milliseconds
        })

      },

    }

  },

  data () {
    return {
      dateNeeded: SessionStorage.getItem('hasExpiry'),
      documentName: SessionStorage.getItem('documentName'),
      dateSelection: '',
      minDate,
      todayDate,
      expiryDate: ref(null),
      sessionTimeout: false,
      resultMsg: '',
      resultType: '',
      resultTitle: '',
      userMessage: false,
      uploadReady: false,
      filePickReady: false
    }
  },

  mounted() {

    if (!this.dateNeeded){
      this.filePickReady = true;
    }
    if (!this.dateNeeded){
      this.showUploadNote('Use the \'+\' button above to select your file', 'purple', 3500);
    }
  },

  methods: {

    expiryChange () {
      //
      //    Expiry date selected/changed
      //
      var selectedDate = new Date(this.expiryDate);
      const day = selectedDate.toLocaleString('default', { day: '2-digit' });
      const month = selectedDate.toLocaleString('default', { month: 'short' });
      const year = selectedDate.toLocaleString('default', { year: 'numeric' });
      var formattedDate =  day + '-' + month + '-' + year;
      this.dateSelection = 'Expiry date: ' + formattedDate;

      this.filePickReady = true;
    },

    resetDate () {
      this.uploadReady = false;
      this.filePickReady = false;
    },

    fileAdded () {
      //
      //    File added for upload - set cookies
      //
      document.cookie = 'UserEmail=' + SessionStorage.getItem('userEmail');
      document.cookie = 'InstallerId=' + SessionStorage.getItem('installerId');
      document.cookie = 'InstallerCompanyId=' + SessionStorage.getItem('installerCompanyId');
      document.cookie = 'InstallerName=' + SessionStorage.getItem('installerName');
      document.cookie = 'ChecklistType=' + SessionStorage.getItem('checkType');
      document.cookie = 'ChecklistId=' + SessionStorage.getItem('checklistId');
      document.cookie = 'CheckName=' + SessionStorage.getItem('documentName');
      document.cookie = 'SessionKey=' + SessionStorage.getItem('sessionKey');
      if (this.expiryDate)
        document.cookie = 'ExpiryDate=' + this.expiryDate.replace(/\//g, "-");
      else
        document.cookie = 'ExpiryDate=NULL';
      document.cookie = 'DocumentType=' + this.documentName;
      this.uploadReady = true;
      this.showUploadNote('Use the \'Upload Now\' button above to upload your file', 'purple', 3500);
    },

    fileRemoved () {
      //
      //    File removed
      //
      this.uploadReady = false;
    },

    uploadFile () {
      //
      //    invoke upload method on q-uploader
      //
      this.$refs.qUploaderRef.upload();
    },

    handleReject (rejectedEntries) {
      //
      //    upload rejected - must be violating size or file type constraint
      //
      var validationType = rejectedEntries[0].failedPropValidation;
      var uploadFile = rejectedEntries[0].file;
      console.log(rejectedEntries);
      console.log('Upload reject: ' + validationType + ' ' + uploadFile);
      if (validationType == 'accept') {
        this.resultTitle = 'Wrong file type';
        this.resultMsg = 'Please select one of the following file types: .pdf, .gif, .jpg, .docx or .png';
      }
      else {
        this.resultTitle = 'File too large';
        this.resultMsg = 'The document must be no bigger than 10MB. Please use a smaller file.';
      }
      this.resultType = 'Error';
      this.userMessage = true;
    },

    showUploadResult () {
      //
      //    File upload done - show results
      //

      //    Reflect changes locally
      var installerChecklist = new Array();
      installerChecklist = SessionStorage.getItem('checkList');
      var itemIx = SessionStorage.getItem('listRow');
      //console.log(installerChecklist[itemIx]);
      installerChecklist[itemIx].cb = true;
      installerChecklist[itemIx].textLine2 = 'Pending';
      if (this.expiryDate) {
        var selectedDate = new Date(this.expiryDate);
        const day = selectedDate.toLocaleString('default', { day: '2-digit' });
        const month = selectedDate.toLocaleString('default', { month: 'short' });
        const year = selectedDate.toLocaleString('default', { year: 'numeric' });
        var formattedDate =  day + '-' + month + '-' + year;
        installerChecklist[itemIx].textLine1 = 'Expires: ' + formattedDate;
        installerChecklist[itemIx].expiryDate = this.expiryDate.replace(/\//g, "-");
      }
      else {
        installerChecklist[itemIx].textLine1 = 'This does not expire';
      }
      installerChecklist[itemIx].cb = true;
      installerChecklist[itemIx].cbCol = 'green-3';
      installerChecklist[itemIx].txtCol = 'text-grey-8';
      installerChecklist[itemIx].exists = true;
      installerChecklist[itemIx].documentStatus = 'Pending';
      //console.log(installerChecklist[itemIx]);
      SessionStorage.set('checkList',installerChecklist);
      //console.log(installerChecklist);

      //  check for messages - using cookie since HTTP response object is not available
      var resultCode = 0;
      var cookieArr = document.cookie.split(";");
      for (var i = 0; i < cookieArr.length; i++) {
        var cookiePair = cookieArr[i].split("=");
        switch (cookiePair[0].trim()) {
          case 'ResultCode': resultCode = cookiePair[1]; break;
          case 'ResultTitle': this.resultTitle = cookiePair[1]; break;
          case 'ResultMsg': this.resultMsg = cookiePair[1]; break;
          case 'ResultType': this.resultType = cookiePair[1]; break;
          default:
        }
      }

      if (resultCode != '10') {
        if (resultCode == '30') {
          this.sessionTimeout = true;
        }
        this.userMessage = true;
      }
      else {
        this.showUploadNote('Your document has been saved and is pending approval', 'green', 3500);
        this.$router.replace('/app/home');
      }
    }

  }
}
</script>
