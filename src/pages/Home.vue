<template>
  <q-page>

    <div class="q-gutter-y-md" style="max-width: 600px">

      <!-- <q-separator /> -->

      <q-carousel
        ref="HomeCarousel"
        v-model="mainName"
        transition-prev="slide-right"
        transition-next="slide-left"
        swipeable
        animated
        navigation-position="bottom"
        navigation-icon="mdi-circle"
        control-color="orange"
        navigation
        padding
        class="rounded-borders"
        style="min-height: 80vh"
      > <!-- height="600px" -->

        <!--  Submit invoice  -->
        <q-carousel-slide name="submitinvoice" class="column no-wrap q-mt-xl">
          <div v-if="hasWorkorders" class="bg-orange-2">
            <q-select v-model="projectRef" bg-color="white" label="Work order" class="q-pt-md-px-sm"
              :options="projectSelect"
              :options-html="true"
              @update:model-value="workOrderSelected"
              outlined dense
              ref="workOrderSelectRef"
            />

            <div v-if="dateNeeded" class="row justify-between items-center q-pa-sm">
              <div class="text-subtitle2 text-blue">
                Select the date range ...
              </div>
              <div class="bg-orange-4">
                <q-btn icon="mdi-close-box-outline" color="orange" @click="closeCalendar()" />
              </div>
            </div>
            <div v-else class="row justify-between items-center q-pa-sm">
              <div class="text-subtitle2 text-grey-9">
                <span v-html="dateSelection"></span>
              </div>
              <div class="bg-orange-4">
                <q-btn icon="mdi-calendar-range" color="orange" @click="resetInvoiceRange()" />
              </div>
            </div>

            <q-date v-if="dateNeeded" v-model="invoiceRange" class="q-ma-xs full-width" minimal color="orange-3" text-color="grey-9" bordered range @update:model-value="invoiceRangeSet()" />
            <!--
            <div class="row">
              <q-input v-model.number="invoiceAmount" label="Invoice amount" :rules=" val => /^\d+(?:\.\d{0,2})$/.test(val) == true || 'Please enter an amount'" inputmode="decimal" prefix="$" outlined class="float-right text-right q-ma-xs" style="max-width: 200px" />
            </div>
            -->
            <div class="row">
              <q-checkbox v-model="noSubcontractor" label="No subcontractors or worker's compensation exempt employer" color="orange" class="text-grey-9"/>
            </div>

            <div v-if="filePickReady && !uploadReady" class="row text-subtitle2 text-blue q-pl-sm">Select your invoice (use '+' below):</div>

            <q-uploader v-if="filePickReady"
              name="Quploader"
              ref="qUploaderRef"
              url="Services/StoreInvoice.aspx"
              :headers="setInvUploadHeaders"
              class="q-ma-xs full-width q-px-sm bg-orange-2"
              style="max-width: 550px"
              max-file-size="10240000"
              @added="invoiceSelected" 
              @removed="invoiceRemoved"
              @finish="checkInvoiceUpload"
              @rejected="showTooLarge" 
              color="orange"
              hide-upload-btn
              text-color="grey-10"
              maxfiles="1"
              accept=".jpg, image/*, .pdf"
              flat
              bordered
            /> <!-- info => checkInvoiceUpload(info) -->
          <div v-if="uploadReady && !workOrderNeeded" class="q-pa-xs">
            <q-btn class="full-width bg-primary text-white" label="Prepare Contractor Statement" icon="mdi-signature-freehand" @click="uploadInvoice()" />
          </div>
          <div v-if="workOrderNeeded" class="q-pa-xs">
            <q-banner class="bg-primary text-white">
              Please select a work order. 
            </q-banner>
          </div>

          </div>
          <div v-if="!hasWorkorders">
            <q-banner class="bg-primary text-white q-pa-xl">
              You do not have any active work orders to invoice against. Please contact CCC with any questions.
            </q-banner>
          </div>

        </q-carousel-slide>

        <!--  Invoices list  -->
        <q-carousel-slide name="invoicelist" class="column no-wrap q-px-xs q-mt-xl">
          <q-list v-if="hasInvoices" class="q-pl-none" bordered>

            <!-- <q-expansion-item group="invoicegroup" v-for="item in installerInvoiceList" :key="item.rowId" :label="item.invoiceText" :caption="item.invoiceStatus" expand-separator dense header-class="item.txtCol"> -->
            <q-expansion-item group="invoicegroup" v-for="item in installerInvoiceList" :key="item.rowId" expand-separator class="q-pl-none">
              <template #header>
                <q-item class="q-pl-none q-py-xs">
                  <q-item-section avatar class="q-pr-none">
                    <q-checkbox :model-value="item.cb" :color="item.cbCol" />
                  </q-item-section>

                  <q-item-section class="q-pr-md">
                    <q-item-label>{{item.invoiceText}}</q-item-label>
                    <q-item-label caption>{{item.invoiceStatus}}</q-item-label>
                  </q-item-section>

                </q-item>
              </template>
              <q-item class="q-pl-none">
                <q-item-section avatar class="q-pr-none">
                  <q-checkbox color="white" />
                </q-item-section>
                <q-item-section>
                  <q-item-label>{{item.projectName}}</q-item-label>
                  <q-item-label caption>{{item.projectRef}}</q-item-label>
                </q-item-section>
                <q-item-section class="q-pr-none q-pl-md" side>
                  <div class="text-grey-8"> 
                    <q-btn class="q-mx-xs" size="12px" round color="primary" icon="mdi-currency-usd" @click="invoiceLook(item.rowId)" >
                      <q-tooltip class="bg-amber text-black" :offset="[10, 20]">
                        Show invoice
                      </q-tooltip>
                    </q-btn>
                    <q-btn class="q-mx-xs" size="12px" round color="primary" icon="mdi-signature-freehand" @click="statementLook(item.rowId)" >
                      <q-tooltip class="bg-amber text-black" :offset="[10, 20]">
                        Show statement
                      </q-tooltip>
                    </q-btn>
                    <!-- Note v-if below -->
                    <q-btn v-if="item.canDelete" class="q-mx-xs" size="12px" round color="warning" icon="mdi-delete" @click="invoiceDelete(item.rowId)" >
                      <q-tooltip class="bg-amber text-black" :offset="[10, 20]">
                        Delete invoice
                      </q-tooltip>
                    </q-btn>
                  </div>
                </q-item-section>
              </q-item>

            </q-expansion-item>

            <q-separator />

<!--
            <q-item class="q-px-xs" v-for="item in installerInvoiceList" :key="item.rowId">
              <q-item-section class="col-1" top>
                <q-checkbox :model-value="item.cb" :color="item.cbCol" />
              </q-item-section>

              <q-item-section top class="col-10 q-py-xs"> 
                <q-item-label class="q-pt-xs" :class="item.txtCol">{{ item.invoiceText }}</q-item-label> -->
                <!-- <q-item-label class="q-pt-xs text-grey-9" :class="item.txtCol">For {{ item.invoiceFrom }} to {{ item.invoiceTo }} is {{ item.invoiceStatus }}</q-item-label> -->
<!--              </q-item-section>

              <q-item-section class="col-1 q-py-xs"> -->
                <!-- Note v-ifs below -->
<!--                <div class="text-grey-8"> 
                  <q-btn v-if="item.resubmit" class="q-gt-xs" size="12px" flat dense round icon="mdi-file-send-outline" @click="invoiceResubmit(item.rowId)" >
                    <q-tooltip class="bg-amber text-black" :offset="[10, 20]">
                      Resubmit invoice
                    </q-tooltip>
                  </q-btn>
                  <q-btn v-else class="q-gt-xs" size="12px" flat dense round icon="mdi-file-eye-outline" @click="invoiceLook(item.rowId)" >
                    <q-tooltip class="bg-amber text-black" :offset="[10, 20]">
                      Show invoice
                    </q-tooltip>
                  </q-btn> -->
                  <!-- <q-btn v-else class="q-gt-xs" size="12px" flat dense round /> -->
<!--                </div>
              </q-item-section>

            </q-item> -->
          </q-list>
          <div v-if="!hasInvoices">
            <q-banner class="bg-primary text-white q-pa-xl">
              You have not submitted any invoices yet. Please contact CCC with any questions. 
            </q-banner>
          </div>

        </q-carousel-slide>

        <!--  Checklist  -->
        <!-- <q-scroll-area class="fit" visible="true"> -->
        <q-carousel-slide name="checklist" class="column no-wrap q-mt-xl">
          <q-list v-if="hasChecklist" class="q-ml-none">
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
                  <q-btn v-if="item.exists" class="q-gt-xs" size="12px" flat dense round icon="mdi-file-eye-outline" @click="documentLook(item.rowId)" >
                    <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                      Show document
                    </q-tooltip>
                  </q-btn>
                  <q-btn v-else class="q-gt-xs" size="12px" flat dense round />
                  <q-btn class="q-gt-xs" size="12px" flat dense round icon="mdi-upload" @click="documentUpload(item.rowId)" >
                    <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                      Upload document
                    </q-tooltip>
                  </q-btn>
                  <q-btn v-if="item.exists" class="q-gt-xs" size="12px" flat dense round icon="mdi-delete" @click="documentDelete(item.rowId)" >
                    <q-tooltip class="bg-amber text-black" :offset="[10, 10]">
                      Delete document
                    </q-tooltip>
                  </q-btn>
                  <q-btn v-else class="q-gt-xs" size="12px" flat dense round />
                </div>
              </q-item-section>

            </q-item>
          </q-list>
          <div v-if="!hasChecklist">
            <q-banner class="bg-primary text-white q-pa-xl">
              You do not have any checklist items. Please contact CCC to resolve this.
            </q-banner>
          </div>
        </q-carousel-slide>
        <!-- </q-scroll-area> -->

      </q-carousel>

      <q-page-sticky expand position="top" style="width: 100%" :offset="[0, 0]">    <!-- Carousel page title -->
        <q-toolbar class="bg-blue-5 text-white">
          <q-toolbar-title v-if="mainName === 'submitinvoice'">Submit Invoice</q-toolbar-title>
          <q-toolbar-title v-if="mainName === 'invoicelist'"><span>Invoice List</span>
            <!-- <q-btn label="Submit an Invoice" class="q-gt-xs float-right" size="12px" flat dense round /> -->
              <q-btn color="orange" class="bg-orange-4 float-right" label="Submit an Invoice" @click="submitInvoice()" />
          </q-toolbar-title>
          <q-toolbar-title v-if="mainName === 'checklist'">Checklist</q-toolbar-title>
        </q-toolbar>
      </q-page-sticky>

    </div>

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
import { useRoute } from 'vue-router';
import { watch } from 'vue';
import { ref } from 'vue';
import { SessionStorage } from 'quasar';
import { useQuasar } from 'quasar';
import axios from 'axios';

export default {

  setup () {
    const $q = useQuasar();

    return {

      showUploadNote (text, colour, milliseconds) {
        $q.notify({
          message: text,
          color: colour,
          timeout: milliseconds
        })
      }
    }
  },

  mounted() {
    //
    //    show carousel slide requested from menu and set watch for other menu navigation
    //
    if (!SessionStorage.getItem('signatureStatus')) {    //    i.e. navigating with 'back' after logged out
      this.$router.replace('');
      return;
    }

    const route = useRoute();
    if (route.params.page != null) {          //  mounting from menu (another page shown)
      var mainName = route.params.page;
      this.$refs.HomeCarousel.goTo(mainName);
      //alert('from another page');
    }
    watch(
      () => route.params.page,                //  changing carousel from the menu (not by swipe/tap)
      async newPage => {
        if (newPage != null) {
          //alert('menu carousel change');
          this.$refs.HomeCarousel.goTo(newPage);
        }
      }
    )
  },

  data () {
    //
    //
    //
    var dateToday = new Date();
    const day = dateToday.toLocaleString('default', { day: '2-digit' });
    const month = dateToday.toLocaleString('default', { month: '2-digit' });
    const year = dateToday.toLocaleString('default', { year: 'numeric' });
    var minDate = year + '/' + month;
    var todayDate = minDate + '/' + day;

    const dayOfWeek = dateToday.getDay();
    var endOfWeek = new Date();
    endOfWeek.setDate(endOfWeek.getDate() - ((dayOfWeek == 6) ? -1 : dayOfWeek) - 1);
    var startOfWeek = new Date();
    startOfWeek.setDate(startOfWeek.getDate() - dayOfWeek - ((dayOfWeek == 6) ? 0 : 7));
    console.log(dayOfWeek);
    console.log(startOfWeek);
    console.log(endOfWeek);
    var invoiceRangeFrom;
    var invoiceRangeTo;
    var formattedFromDate;
    var formattedToDate;
    invoiceRangeFrom = startOfWeek.toISOString().split('T')[0].replaceAll('-','/');
    invoiceRangeTo = endOfWeek.toISOString().split('T')[0].replaceAll('-','/');
    formattedFromDate = startOfWeek.toLocaleString().split(',')[0];
    formattedToDate = endOfWeek.toLocaleString().split(',')[0];

    //const todaydd = dateToday.toLocaleString('default', { day: '2-digit' });
    //const todaymm = dateToday.toLocaleString('default', { month: '2-digit' });
    //const todayyy = dateToday.toLocaleString('default', { year: '2-digit' });
    console.log('Range: '+invoiceRangeFrom+' '+invoiceRangeTo);

    return {
      installerChecklist: new Array(),
      installerInvoiceList: new Array(),
      projectList: new Array(),
      cehcklistPLok: false,
      dateNeeded: true,
      dateSelection: 'Invoice is for <b class="text-blue">' + formattedFromDate + '</b> to <b class="text-blue">' + formattedToDate + '</b>',
      workOrderNeeded: true,
      filePickReady: false,
      confirmDelete: false,
      invoiceReady: false,
      uploadReady: false,
      noSubcontractor: true,
      hasChecklist: false,
      hasInvoices: false,
      hasWorkorders: false,
      mainName: 'invoicelist',
      projectSelect: new Array(),
      projectRef: null,
      statementData: null,
      invoiceRange: ref({ from: invoiceRangeFrom, to: invoiceRangeTo }),
      invoiceAmount: 0,
      requestHeaders: new Array(),
      userMessage: false,
      sessionTimeout: false,
      todayDate: todayDate,
      resultMsg: '',
      resultType: '',
      resultTitle: ''
    }
  },

  watch: {
    mainName(newPage) {
      if (newPage == 'submitinvoice') {
        if (!this.checklistPLok) {
          this.resultMsg = 'Public liability on your checklist is not checked. This is needed to proceed. Contact CCC if you have questions.';
          this.resultType = 'Error';
          this.resultTitle = 'Public Liability Needed';
          this.userMessage = true;
        }
      }
      //  alert('Tap going to '+ newPage);
    }
  },

  created () {
    //
    //        Refresh lists on browser refresh
    //
    this.dateNeeded = false;
    this.filePickReady = true;

    axios.get('Services/GetInstallerLists.aspx', {
      headers: {
        'Content-Type': 'multipart/form-data',
        'UserEmail': SessionStorage.getItem('userEmail'),
        'InstallerId': SessionStorage.getItem('installerId'),
        'InstallerCompanyId': SessionStorage.getItem('installerCompanyId'),
        'SessionKey': SessionStorage.getItem('sessionKey')
      },
    })
    .then(response => {
      //    Check result message
      console.log('home created');
      var postResponse = response.data;
      //console.log(postResponse);
      //console.log('result code');
      //console.log(postResponse.resultCode);
      if (postResponse.resultCode != 0) {
        this.resultMsg = postResponse.resultMsg;
        this.resultType = postResponse.resultType;
        this.resultTitle = postResponse.resultTitle;
        if (postResponse.resultCode == 30) {
          this.sessionTimeout = true;
        }
        this.userMessage = true;
      }
      else {
        var setCheckListResult = this.setCheckList(postResponse.checkList);
        this.installerChecklist = setCheckListResult.checkList;
        this.checklistPLok = setCheckListResult.checklistPLok;
        this.installerInvoiceList = this.setInvoiceList(postResponse.invoiceList);
        this.projectSelect = this.setProjectSelect(postResponse.projectList);
        this.statementData = postResponse.statementData;
        this.$router.replace('/app/home/invoicelist');
      }
    })
    .catch(error => {
      console.log(error);
      this.resultMsg = "System error: " + error.response.status + ". Please contact CCC.";
      this.resultType = "System Error";
      this.resultTitle = "System Error";
      this.userMessage = true;
    });

  },

  methods: {

    //  ***     Submit Invoice

    setProjectSelect (projectList) {
      //
      //      Populate the checklist object from the GetInstallerlists service response
      //
      var projectId;
      var projectDescription;
      var projectSelect = [];
      if (projectList.length > 0)
        this.hasWorkorders = true;
      for (let i = 0; i < projectList.length; i++) {
        projectId = projectList[i].projectRefNo;
        projectDescription = '<b>' + projectId + '</b>: ' + projectList[i].projectName // + ' for ' + projectList[i].jobCustomer;
        var selectItem = {value: projectId, label: projectDescription};
        projectSelect.push(selectItem);
      }
      if (projectList.length == 1) {    //    auto select if just one work order
        this.projectRef = {value: projectSelect[0].value, label: projectSelect[0].label};
        this.workOrderNeeded = false;
      }
      //SessionStorage.set('projectList',projectList);
      //console.log(projectList);
      return projectSelect;
    },

    workOrderSelected () {
      this.workOrderNeeded = false;
    },

    submitInvoice () {
      this.$refs.HomeCarousel.goTo('submitinvoice');    //  going to the invoice submit on the home component carousel
    },

    invoiceRangeSet () {
      //
      //    Expiry date selected/changed
      //
      console.log('Project: ');
      //console.log(this.projectRef.value);   //    ******************** check order???
      console.log('Date range');
      console.log(this.invoiceRange.from+' '+this.invoiceRange.to);
      var fromDate = this.invoiceRange.from;

      var toDate = this.invoiceRange.to;
      //var day = fromDate.toLocaleString('default', { day: '2-digit' });
      //var month = fromDate.toLocaleString('default', { month: 'short' });
      //var year = fromDate.toLocaleString('default', { year: 'numeric' });
      var formattedFromDate = fromDate.substring(8,10) + '-' + fromDate.substring(5,7) + '-' + fromDate.substring(0,4);
      //var formattedFromDate =  day + '-' + month + '-' + year;
      //day = toDate.toLocaleString('default', { day: '2-digit' });
      //month = toDate.toLocaleString('default', { month: 'short' });
      //year = toDate.toLocaleString('default', { year: 'numeric' });
      //var formattedToDate =  day + '-' + month + '-' + year;
      var formattedToDate =  toDate.substring(8,10) + '-' + toDate.substring(5,7) + '-' + toDate.substring(0,4);
      this.dateSelection = 'Invoice is for <b class="text-blue">' + formattedFromDate + '</b> to <b class="text-blue">' + formattedToDate + '</b>';
      this.dateNeeded = false;
      this.filePickReady = true;

      //this.filePickReady = true;
    },

    resetInvoiceRange () {
      this.dateNeeded = true;
      this.filePickReady = false;
    },

    closeCalendar () {
      this.dateNeeded = false;
      this.filePickReady = true;
    },

    invoiceSelected () {
      //
      //    Invoice added for upload - set cookies
      //
      this.uploadReady = true;
      this.showUploadNote('Use the \'Prepare Contractor Statement\' button above to upload your invoice', 'purple', 3500);
    },

    invoiceRemoved () {
      //
      //    Invoice selected for upload removed
      //
      this.uploadReady = false;
    },

    uploadInvoice () {
      //
      //    invoke upload method on q-uploader
      //
      this.$refs.qUploaderRef.upload();
    },

    checkInvoiceUpload () {
      //  check for messages - using cookie since HTTP response object is not available
      var resultCode = 0;
      var statementId;
      var cookieArr = document.cookie.split(";");
      for (var i = 0; i < cookieArr.length; i++) {
        var cookiePair = cookieArr[i].split("=");
        switch (cookiePair[0].trim()) {
          case 'ResultCode': resultCode = cookiePair[1]; break;
          case 'ResultTitle': this.resultTitle = cookiePair[1]; break;
          case 'ResultMsg': this.resultMsg = cookiePair[1]; break;
          case 'ResultType': this.resultType = cookiePair[1]; break;
          case 'StatementId': statementId = cookiePair[1]; break;
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
        console.log('invoice uploaded...');
        SessionStorage.set('statementId',statementId)
        this.doStatement(statementId);
      }
    },

    setInvUploadHeaders () {
      //
      //    set headers for request
      //
      var hdrDateFrom = this.invoiceRange.from.substring(0,4) + '-' + this.invoiceRange.from.substring(5,7) + '-' + this.invoiceRange.from.substring(8);
      var hdrDateTo = this.invoiceRange.to.substring(0,4) + '-' + this.invoiceRange.to.substring(5,7) + '-' + this.invoiceRange.to.substring(8);
      this.requestHeaders = [{name: 'SessionKey', value: SessionStorage.getItem('sessionKey') },
                    {name: 'UserEmail', value: SessionStorage.getItem('userEmail') },
                    {name: 'InstallerId', value: SessionStorage.getItem('installerId') }, 
                    {name: 'InstallerCompanyId', value: SessionStorage.getItem('installerCompanyId') },
                    {name: 'InstallerName', value: SessionStorage.getItem('installerName') },
                    {name: 'ProjectRef', value: this.projectRef.value },
                    {name: 'DateFrom', value: hdrDateFrom },
                    {name: 'DateTo', value: hdrDateTo } ];
      console.log('Header v1');
      console.log(this.requestHeaders);
      return this.requestHeaders;
    },

    doStatement (statementId) {
      //
      //      User has requested the Contractor Statement to be prepared
      //

      //      set and store data for Contractor Statement
      this.statementData.noSubcontractor = this.noSubcontractor;
      this.statementData.projectRef = 'CCC job: ' + this.projectRef.value;
      this.statementData.workFromdd = this.invoiceRange.from.substring(8);
      this.statementData.workFrommm = this.invoiceRange.from.substring(5,7);
      this.statementData.workFromyy = this.invoiceRange.from.substring(2,4);
      this.statementData.workTodd = this.invoiceRange.to.substring(8);
      this.statementData.workTomm = this.invoiceRange.to.substring(5,7);
      this.statementData.workToyy = this.invoiceRange.to.substring(2,4);
      this.statementData.id = statementId;

      SessionStorage.set('statementData',this.statementData);
      SessionStorage.set('signatureSource','statement');
      var signatureStatus = SessionStorage.getItem('signatureStatus');
      if (signatureStatus == 'none') {           //    no signature recorded - capture it and then proceed to statement
        console.log('no signature');
        this.$router.push('/app/SignPad');
      }
      else {      //    statement will attempt to retrieve the signature
        console.log('signature: '+signatureStatus);
        this.$router.push('/app/showstatement');
      }

    },

    //  ***     Invoice List

    setInvoiceList (resultList) {
      //
      //      Populate the checklist object from the GetInstallerlists service response
      //
      var invoiceId;
      var invoiceFrom;
      var invoiceTo;
      var invoiceStatus;
      var cbTick;
      var cbColour;
      var textColour;
      var invoiceText;
      var fromDate;
      var fromDateDMY;
      var toDate;
      var toDateDMY;
      var canDelete;
      var projectName;
      var projectRef;
      var invoiceList = [];

      if (resultList.length > 0)
        this.hasInvoices = true;
      for (let i = 0; i < resultList.length; i++) {
        invoiceId = resultList[i].ID;
        invoiceFrom = resultList[i].invoiceFrom;
        invoiceTo = resultList[i].invoiceTo;
        invoiceStatus = resultList[i].P[0].S[0].invoiceStatus;
        projectName = resultList[i].P[0].projectName;
        projectRef = resultList[i].projectRefNo;
        fromDate = new Date(invoiceFrom);
        var day = fromDate.toLocaleString('default', { day: '2-digit' });
        var month = fromDate.toLocaleString('default', { month: 'short' });
        var year = fromDate.toLocaleString('default', { year: '2-digit' });
        fromDateDMY = day + '-' + month + '-' + year;
        toDate = new Date(invoiceTo);
        day = toDate.toLocaleString('default', { day: '2-digit' });
        month = toDate.toLocaleString('default', { month: 'short' });
        year = toDate.toLocaleString('default', { year: '2-digit' });
        toDateDMY = day + '-' + month + '-' + year;
        invoiceText = 'Invoice from ' + fromDateDMY + ' to ' + toDateDMY;
        if (invoiceStatus == 'Paid' || invoiceStatus == 'Approved')
        {
          cbTick = true;
          cbColour = 'green';
          textColour = 'text-grey-9';
          canDelete = false;
        }
        else {
          cbTick = null;
          cbColour = 'red';
          textColour = 'text-red';
          canDelete = true;
        }
        var invoiceItem = {rowId: i, id: invoiceId, cb: cbTick, cbCol: cbColour, projectName: projectName, projectRef: projectRef, invoiceTo: invoiceTo, invoiceFrom: invoiceFrom, invoiceStatus: invoiceStatus, invoiceText: invoiceText, txtCol: textColour, canDelete: canDelete}
        invoiceList.push(invoiceItem);

      }
      SessionStorage.set('invoiceList',invoiceList);
      //console.log(invoiceList);
      return invoiceList;
    },

    invoiceLook(rowId) {
      //
      //      Show the invoice ***************  show statement
      //
      SessionStorage.set('invoiceId',this.installerInvoiceList[rowId].id);
      SessionStorage.set('invoiceLabel',this.installerInvoiceList[rowId].invoiceText);
      SessionStorage.set('invoiceStatus',this.installerInvoiceList[rowId].invoiceStatus);
      this.$router.push('/app/showInvoice');
    },

    statementLook(rowId) {
      //
      //      Show the statement ***************  show statement
      //
      SessionStorage.set('invoiceId',this.installerInvoiceList[rowId].id);
      SessionStorage.set('invoiceLabel',this.installerInvoiceList[rowId].invoiceText);
      SessionStorage.set('invoiceStatus',this.installerInvoiceList[rowId].invoiceStatus);
      this.$router.push('/app/showInvoice');
    },

    //confirmDelete(rowId) {
    //  alert('need to confirm');
    //  console.log('deleteing invoice/statement');
    //  console.log(rowId);
    //},

    invoiceDelete(rowId) {
      //
      //      Delete the statement and invoice (if not paid) ***************  to do
      //

      //  ***************** confirm -> delete.aspx
      //
      //    Cancel confirmed: remove invoice and statement files and go back to submit invoice screen
      //

      axios.get('Services/DeleteStatement.aspx', {
        headers: {
          'Content-Type': 'multipart/form-data',
          'UserEmail': SessionStorage.getItem('userEmail'),
          'StatementId': this.installerInvoiceList[rowId].id,
          'StatementFile': this.statementPath,
          'DeleteType': 'both',
          'SessionKey': SessionStorage.getItem('sessionKey')
        },
      })
      .then(response => {
        //    Check result message
        console.log('statement cancelled');
        var postResponse = response.data;
        //console.log(postResponse);
        //console.log('result code');
        //console.log(postResponse.resultCode);
        if (postResponse.resultCode != 10) {
          this.resultMsg = postResponse.resultMsg;
          this.resultType = postResponse.resultType;
          this.resultTitle = postResponse.resultTitle;
          if (postResponse.resultCode == 30) {
            this.sessionTimeout = true;
          }
          this.userMessage = true;
          this.$router.replace('/app/home/invoicelist');
        }
        else {
          //    go back and let the user try agin
          // ************** refresh involice list
          this.showNote('Your invoice and statement have been deleted', 'orange', 3500);
        }
        
      })
      .catch(error => {
        console.log(error);
        this.resultMsg = 'System error: ' + error.response.status + '. Please contact CCC.';
        this.resultType = 'System Error';
        this.resultTitle = 'System Error';
        this.userMessage = true;
        this.$router.replace('/app/home/submitinvoice');
      });
    },

    //  ***     Checklist

    setCheckList (resultList) {
      //
      //      Populate the checklist object from the GetInstallerlists service response
      //
      const publicLiabilityId = 6;    //  database key of the public liability item in table tbl_checklist
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
      var checklistPLok = true;
      const today = new Date();
      var checkList = [];
      if (resultList.length > 0)
        this.hasChecklist = true;
      for (let i = 0; i < resultList.length; i++) {
        checkId = resultList[i].ChecklistID;
        fileName = resultList[i].FileFolderPath;
        expiryDateStr = resultList[i].ExpiryDate;
        if (resultList[i].L == null) {        //        JSON format for installer and company checklist
          checkName = resultList[i].CheckName;
          hasExpiry = resultList[i].HasExpiryDate;
          documentStatus = resultList[i].Status;
          checklistType = resultList[i].Type;
        }
        else {        //        JSON format for installer only checklist
          checkName = resultList[i].L[0].CheckName;
          hasExpiry = resultList[i].L[0].HasExpiryDate;
          documentStatus = resultList[i].L[0].S[0].Status;
          checklistType = resultList[i].L[0].S[0].Type;
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
              if (checkId == publicLiabilityId)   //  Public liaility insurance check
                checklistPLok = false;
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
          if (checkId == publicLiabilityId)    //  Public liaility insurance check
            checklistPLok = false;
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
      SessionStorage.set('checkList',checkList);    //  ************* needed ?
      //console.log(checkList);
      return {checkList: checkList, checklistPLok: checklistPLok};
    },

    documentLook(rowId) {
      //
      //      Show the document uploaded against a checlist item
      //
      SessionStorage.set('checklistId',this.installerChecklist[rowId].id);
      SessionStorage.set('documentName',this.installerChecklist[rowId].checkName);
      SessionStorage.set('documentStatus',this.installerChecklist[rowId].documentStatus);
      SessionStorage.set('checkType',this.installerChecklist[rowId].type);
      this.$router.push('/app/showdocument');
    },

    documentUpload(rowId) {
      //
      //      Upload document required for a checklist item
      //
      SessionStorage.set('listRow',rowId);
      SessionStorage.set('checklistId'.this.installerChecklist[rowId].id);
      SessionStorage.set('documentName',this.installerChecklist[rowId].checkName);
      SessionStorage.set('checkType',this.installerChecklist[rowId].type);
      SessionStorage.set('hasExpiry',this.installerChecklist[rowId].hasExpiry);
      this.$router.push('/app/upload');
    },

    documentDelete(rowId) {
      this.deleteIx = rowId;
      this.confirmDelete = true;
    },
    
    doDelete() {
      //
      //      Delete document uploaded to a checklist item and adjust checklist
      //
      this.confirmDelete = false;

      axios.get('Services/DeleteDocument.aspx.aspx', {
        headers: {
          'Content-Type': 'multipart/form-data',
          'UserEmail': SessionStorage.getItem('userEmail'),
          'InstallerId': SessionStorage.getItem('installerId'),
          'InstallerCompanyId': SessionStorage.getItem('installerCompanyId'),
          'CheckListId': this.installerChecklist[this.deleteIx].id,
          'CheckType': this.installerChecklist[this.deleteIx].type,
          'SessionKey': SessionStorage.getItem('sessionKey')
        },
      })
      .then(response => {
        //    Check result message
        console.log('statement submitted');
        var postResponse = response.data;
        //console.log(postResponse);
        //console.log('result code');
        //console.log(postResponse.resultCode);
        if (postResponse.resultCode != 0) {
          this.resultMsg = postResponse.resultMsg;
          this.resultType = postResponse.resultType;
          this.resultTitle = postResponse.resultTitle;
          if (postResponse.resultCode == 30) {
            this.sessionTimeout = true;
          }
          this.userMessage = true;
        }
        if (this.resultType == 'OK' || this.resultType == 'Information') {
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
      })
      .catch(error => {
        console.log(error);
        this.resultMsg = "System error: " + error.response.status + ". Please contact CCC.";
        this.resultType = "System Error";
        this.resultTitle = "System Error";
        this.userMessage = true;
      });

    },

    showTooLarge () {
      //
      //    upload rejected - must be violating size constraint
      //
      this.resultTitle = 'File too large';
      this.resultMsg = 'The document must be no bigger than 10MB. Please use a smaller file.';
      this.resultType = 'Error';
      this.userMessage = true;
    }

  }
}
</script>
