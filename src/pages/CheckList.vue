<template>
  <q-page padding>

    <q-banner rounded dense class="bg-orange text-white">
      Ready-to-work Checklist
    </q-banner>
    <div class="q-pa-md q-gutter-md">
      <q-list class="q-ml-none">
        <q-item class="q-px-xs" v-for="item in installerChecklist" :key="item.rowId">
          <q-item-section class="col-1" top>
            <q-checkbox :model-value="item.cb" :color="item.cbCol" />
          </q-item-section>

          <q-item-section top class="col-2 q-py-xs">
            <q-item-label class="q-pt-xs text-grey-9">{{ item.checkName }}</q-item-label>
          </q-item-section>

          <q-item-section top class="col-5 q-py-xs">
            <q-item-label class="q-pt-xs">
              <div :class="item.txtCol">{{ item.textLine1 }}</div>
              <div class="text-weight-medium">{{ item.textLine2 }}</div>
            </q-item-label>
          </q-item-section>

          <q-item-section class="col-4 q-py-xs">
            <!-- Note v-ifs below -->
            <div class="text-grey-8"> 
              <q-btn v-if="item.exists" class="q-gt-xs" size="12px" flat dense round icon="mdi-file-eye-outline" @click="itemLook(item.rowId)" >
                <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                  Show document
                </q-tooltip>
              </q-btn>
              <q-btn v-else class="q-gt-xs" size="12px" flat dense round />
              <q-btn class="q-gt-xs" size="12px" flat dense round icon="mdi-upload" @click="itemUpload(item.rowId)" >
                <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                  Upload document
                </q-tooltip>
              </q-btn>
              <q-btn v-if="item.exists" class="q-gt-xs" size="12px" flat dense round icon="mdi-delete" @click="itemDelete(item.rowId)" >
                <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                  Delete document
                </q-tooltip>
              </q-btn>
              <q-btn v-else class="q-gt-xs" size="12px" flat dense round />
            </div>
          </q-item-section>

        </q-item>
      </q-list>

    <q-dialog v-model="confirmDelete" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-icon name="mdi-alert-octagon" class="text-orange-9" style="font-size:4em" />
          <span class="q-ml-sm">Are you sure you want to delete this document?</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Yes" color="orange-9" @click="doDelete()" />
          <q-btn flat label="No" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
    </div>
  </q-page>

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

</template>

<script>
import { ref } from 'vue';
import { SessionStorage } from 'quasar';
//import globalData from 'src/components/GlobalData.js'

export default {

  data () {
    return {
      installerChecklist: new Array(),
      userMessage: false,
      deleteIx: 0,
      deleteType: '',
      confirmDelete: ref(false),
      sessionTimeout: false,
      resultMsg: '',
      resultType: '',
      resultTitle: ''
    }
  },

  created () {
    //
    //        refresh checklist on browser refresh
    //
    const xhttp = new XMLHttpRequest();
    var resultCode = 0;
    xhttp.onload = () => {
      if (xhttp.status != 200) {
        this.resultMsg = 'System error (code ' + xhttp.status + ')';
        this.resultType = 'System Error';
        this.resultTitle = 'System Error';
        this.userMessage = true;
        return;
      }
      var resultObj = JSON.parse(xhttp.response);
      console.log(resultObj);
      resultCode = parseInt(resultObj.resultCode);
      //    Show error/message results
      if (resultCode != 0) {
        //alert('Message: '+this.resultMsg+' - '+this.resultText);
        this.resultMsg = resultObj.resultMsg;
        this.resultType = resultObj.resultType;
        this.resultTitle = resultObj.resultTitle;
        if (resultCode == 30) {
          this.sessionTimeout = true;
        }
        this.userMessage = true;
        return;
      }

      if (this.resultType != 'Error' && this.resultType != 'System Error') {   //  Login OK
        //  get checklist data and save
        this.installerChecklist = this.setCheckList(resultObj);
      }
    }
    xhttp.open('GET', 'Services/GetChecklist.aspx', true);
    xhttp.setRequestHeader('UserEmail', SessionStorage.getItem('userEmail'));
    xhttp.setRequestHeader('InstallerId', SessionStorage.getItem('installerId'));
    xhttp.setRequestHeader('InstallerCompanyId', SessionStorage.getItem('installerCompanyId'));
    xhttp.setRequestHeader('SessionKey', SessionStorage.getItem('sessionKey'));
    xhttp.send();
  },

  methods: {
    itemLook(rowId) {
      SessionStorage.set('checklistId',this.installerChecklist[rowId].id);
      SessionStorage.set('documentName',this.installerChecklist[rowId].checkName);
      SessionStorage.set('documentStatus',this.installerChecklist[rowId].documentStatus);
      SessionStorage.set('checkType',this.installerChecklist[rowId].type);
      this.$router.push('/app/ShowImage');
    },

    itemUpload(rowId) {
      SessionStorage.set('listRow',rowId);
      SessionStorage.set('checklistId',this.installerChecklist[rowId].id);
      SessionStorage.set('documentName',this.installerChecklist[rowId].checkName);
      SessionStorage.set('.checkType',this.installerChecklist[rowId].type);
      SessionStorage.set('hasExpiry',this.installerChecklist[rowId].hasExpiry);
      this.$router.push('/app/Upload');
    },

    itemDelete(rowId) {
      this.deleteIx = rowId;
      this.confirmDelete = true;
    },
    
    doDelete() {

      this.confirmDelete = false;
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
        //console.log('Result: ['+resultCode+'], ['+this.resultMsg+'], ['+this.resultType+'], ['+this.resultTitle+']');
        //    Show error/message results

        if (resultCode != 0) {
          //alert('Message: '+this.resultMsg+' - '+this.resultText);
          this.resultMsg = resultObj.resultMsg;
          this.resultType = resultObj.resultType;
          this.resultTitle = resultObj.resultTitle;
          if (resultCode == 30) {
            this.sessionTimeout = true;
          }
          this.userMessage = true;
          if (this.resultType == 'Error' || this.resultType == 'System Error') {
            return;
          }
        }
        //  get checklist data and save
        //console.log(SessionStorage.getItem('CheckList'));
        this.installerChecklist = SessionStorage.getItem('checkList');
        //var itemIx = this.installerChecklist.findIndex(x => x.id === deleteItem);
        //console.log(this.installerChecklist[itemIx]);
        this.installerChecklist[this.deleteIx].cb = null;
        this.installerChecklist[this.deleteIx].textLine1 = 'Document not provided';
        this.installerChecklist[this.deleteIx].textLine2 = '';
        this.installerChecklist[this.deleteIx].expiryDate = null;
        this.installerChecklist[this.deleteIx].cbCol = 'red';
        this.installerChecklist[this.deleteIx].txtCol = 'text-red';
        this.installerChecklist[this.deleteIx].exists = false;
        this.installerChecklist[this.deleteIx].documentStatus = 'None';
        //console.log(this.installerChecklist[itemIx]);
        SessionStorage.set('checkList',this.installerChecklist);
        console.log('Delete done');
      }
      xhttp.open('POST', 'Services/DeleteDocument.aspx', true);
      xhttp.setRequestHeader('Content-Type','multipart/form-data');
      xhttp.setRequestHeader('InstallerId', SessionStorage.getItem('installerId'));
      xhttp.setRequestHeader('InstallerCompanyId', SessionStorage.getItem('installerCompanyId'));
      xhttp.setRequestHeader('CheckListId', this.installerChecklist[this.deleteIx].id);
      xhttp.setRequestHeader('CheckType', this.installerChecklist[this.deleteIx].type);
      xhttp.setRequestHeader('SessionKey', SessionStorage.getItem('sessionKey'));
      xhttp.send();

    },

    setCheckList (resultObj) {
      //
      //      Populate the checklist object from the GetChecklist service response
      //
      var checkId;
      var checkName;
      var hasExpiry;     //  true = expiry is mandatory
      var documentStatus;
      var docExists;
      var cbTick;
      var cbColour;
      var textLine1;
      var textLine2;
      var textColour
      var expiryDate;
      var expiryDateStr;
      var expiryDateDMY;
      var fileName;
      var checklistType;    //  I - installer, C - company
      const today = new Date();
      var checkList = [];
      for (let i = 0; i < resultObj.checkList.length; i++) {
        checkId = resultObj.checkList[i].ChecklistID;
        fileName = resultObj.checkList[i].FileFolderPath;
        expiryDateStr = resultObj.checkList[i].ExpiryDate;
        if (resultObj.checkList[i].L == null) {        //        JSON format for installer and company checklist
          checkName = resultObj.checkList[i].CheckName;
          hasExpiry = resultObj.checkList[i].HasExpiryDate;
          documentStatus = resultObj.checkList[i].Status;
          checklistType = resultObj.checkList[i].Type;
        }
        else {        //        JSON format for installer only checklist
          checkName = resultObj.checkList[i].L[0].CheckName;
          hasExpiry = resultObj.checkList[i].L[0].HasExpiryDate;
          documentStatus = resultObj.checkList[i].L[0].S[0].Status;
          checklistType = resultObj.checkList[i].L[0].S[0].Type;
        }
        if (fileName == null)
          docExists = false;
        else
          docExists = true;
        textColour = 'text-grey-8';
        textLine2 = '';
        if (hasExpiry) {
          if (expiryDateStr) {
            expiryDate = new Date(expiryDateStr);
            //console.log('Exp: ' + expiryDate.toLocaleString('default'));
            const day = expiryDate.toLocaleString('default', { day: '2-digit' });
            const month = expiryDate.toLocaleString('default', { month: 'short' });
            const year = expiryDate.toLocaleString('default', { year: 'numeric' });
            expiryDateDMY = day + '-' + month + '-' + year;
          }
        }
        else {
          expiryDate = null;
          expiryDateDMY = '';
        }

        textLine2 = '';
        if (documentStatus == 'Active' || documentStatus == 'Pending') {
          if (!hasExpiry) {
            cbTick = true;
            cbColour = 'green';
            textLine1 = 'This does not expire';
            textColour = 'text-grey-9';
          }
          else {
            if (expiryDate > today) {
              cbTick = true;
              cbColour = 'green';
              textLine1 = 'Expires: ' + expiryDateDMY;
              textColour = 'text-grey-9';
              var triggerDate = new Date();
              triggerDate.setDate(triggerDate.getDate() + 21); // 21 days is set as threshold (config?)
              if (expiryDate < triggerDate) {
                cbColour = 'orange';
                textColour = 'text-orange-8';
                var daysToGo = Math.round((expiryDate - today)/(1000*60*60*24));
                textLine2 = daysToGo.toString() + ' day' + ((daysToGo == 1) ? '' : 's');
              }
            }
            else {
              cbTick = null;
              cbColour = 'red';
              textLine1 = 'Expired: ' + expiryDateDMY;
              textColour = 'text-red';
            }
          }
          if (documentStatus == 'Pending') {
            cbColour = 'green-3';
            textLine2 = 'Pending';
          }
        }
        else {          //  No document, or expired or assessed as invalid
          cbTick = null;
          cbColour = 'red';
          textColour = 'text-red';
          expiryDate = null;
          if (documentStatus == 'None') {
            textLine1 = 'Document not provided';
          }
          else{
            if (documentStatus == 'Rejected') {
              textLine1 = 'Invalid document provided';
            }
            else {
              if (documentStatus == 'Expired')
                textLine1 = 'Expired: ' + expiryDateDMY;
              else
                textLine1 = 'Status is ' + documentStatus;
            }
          }
        }
        var checkItem = {rowId: i, id: checkId, cb: cbTick, checkName: checkName, textLine1: textLine1, textLine2: textLine2, hasExpiry: hasExpiry, expiryDate: expiryDate, documentStatus: documentStatus, cbCol: cbColour, txtCol: textColour, exists: docExists, type: checklistType};
        //console.log(checkItem);
        checkList.push(checkItem);
      }
      SessionStorage.set('checkList',checkList);
      //console.log(checkList);
      return checkList;

    }

  }
}
</script>
