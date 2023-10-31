<template>
  <q-page padding>

    <div class="q-pa-md q-gutter-sm">
      <q-card class="q-ma-none column" transition-show="slide-left">
        <q-item class="bg-orange-3">
          <q-item-section>
            <q-item-label class="text-large">Contractor Statement</q-item-label>
          </q-item-section>

          <!-- <q-item-section side>
            <q-btn size="12px" flat dense round icon="mdi-close" @click="showListTabs"> 
            </q-btn>
          </q-item-section> -->
        </q-item>

        <q-item>
          <div class="q-pa-md q-gutter-sm full-width" style="height: 65vh;"> <!-- ******************  width ********** -->
            <q-pdfviewer
              type="html5"
              :src="statementSource"
              error-string="This browser cannot view pdfs. Download the pdf to view it"
            />
          </div> 
        </q-item>

        <div class="row">
          <div class="col-6 q-px-xs">
            <q-btn label="Submit" class="full-width" color="primary" @click="submitStatement"></q-btn>
          </div>
          <div class="col-6 q-px-xs">
            <q-btn label="Cancel" class="full-width" color="orange-8" @click="checkCancel"></q-btn>
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
          <q-btn v-if="sessionTimeout" flat label="OK" color="orange-9" to="/Login" /> <!-- back to login if there is a timeout -->
          <q-btn v-else flat label="OK" color="orange-9" to="/app/home/submitinvoice" /> <!-- back to the form if there is a system error -->
        </q-card-actions>

      </q-card>
    </q-dialog>

    <!--   Dialog   -->
    <q-dialog v-model="confirmCancel" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-icon name="mdi-alert-octagon" class="text-orange-9" style="font-size:4em" />
          <span class="q-ml-sm">Are you sure you <b>do not</b> want to submit the invoice and sign the statement?</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Yes" color="warning"  @click="cancelInvoice" />
          <q-btn flat label="No" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>

  </q-page>
</template>

<script>
import { PDFDocument } from 'pdf-lib';
import { SessionStorage } from 'quasar';
import { useQuasar } from 'quasar';
import axios from 'axios';

export default {

  setup () {
    const $q = useQuasar();

    return {

      showNote (text, colour, milliseconds) {
        $q.notify({
          message: text,
          color: colour,
          timeout: milliseconds
        })
      }
    }
  },

  data () {
    return {
      resultMsg: '',
      resultType: '',
      resultTitle: '',
      userMessage: false,
      sessionTimeout: false,
      confirmCancel: false,
      statementSource: '',
      statementStatus: 'ready',
      statementPath: null
    }
  },

  mounted () {
    this.generateStatement();
  },

  methods: {

    async generateStatement() {
      //
      //      Generate Subcontractor Statement
      //

      //      get signature/work out if not captured
      var signatureStatus = SessionStorage.getItem('signatureStatus');
      console.log('generate form started with '+signatureStatus);

      var signImageBytes;
      //  look for signature: get file, if none - show sign pad

      var pngUrl = 'CEPData/Signatures/Signature-' + SessionStorage.getItem('installerId') + '.png';

      var response = await fetch(pngUrl);
      console.log('Fetch signature response: ' + response.statusText);
      //console.log(response.status); // 200
      if (response.status === 200) {
        // var context = this;
        SessionStorage.set('signatureStatus','saved');
        signatureStatus = 'saved';
        signImageBytes = await response.arrayBuffer();
        //console.log('signature bytes');
        //console.log(signImageBytes);
      }
      else {
        SessionStorage.set('signatureStatus','none');
        signatureStatus = 'none';
        signImageBytes = null;
        //if (response.status != 404) {
        //  alert('error getting signature ' + response.status);
        //  return;
      }

      if (signatureStatus == 'none') {     //    no signature recorded - capture it
        // SessionStorage.set('statementData',statementData);
        SessionStorage.set('signatureSource','statement');
        this.$router.replace('/app/SignPad');
        return;
      }

      //    To get here, we must have fetched the signature. Now get the form template and data
      var statementData = SessionStorage.getItem('statementData');

      const formUrl = 'CEPdata/SC Form.pdf';      //    the form template to be filled
      const formPdfBytes = await fetch(formUrl).then(res => res.arrayBuffer());
      const pdfDoc = await PDFDocument.load(formPdfBytes);
      const form = pdfDoc.getForm();
      const fields = form.getFields()
      console.log('form fields:');
      fields.forEach(field => {
        const type = field.constructor.name
        const name = field.getName()
        console.log(`${type}: ${name}`)
      })
      console.log('contractor statement form retrieved');
      console.log(statementData);
      var dateToday = new Date();
      const todaydd = dateToday.toLocaleString('default', { day: '2-digit' });
      const todaymm = dateToday.toLocaleString('default', { month: '2-digit' });
      const todayyy = dateToday.toLocaleString('default', { year: '2-digit' });

      const formAddress = form.getTextField('address');
      formAddress.setText(statementData.address);
      const formContractor = form.getTextField('principal contractor');
      formContractor.setText(statementData.businessName);
      const formContract = form.getTextField('contact number/identifier/name');
      formContract.setText(statementData.projectRef);
      const formDirector = form.getTextField('director name');
      formDirector.setText(SessionStorage.getItem('installerName'));
      const formPosition = form.getTextField('position');
      formPosition.setText(statementData.signerTitle);
      const formABN = form.getTextField('ABN 1');
      formABN.setText(statementData.ABN);
      const formName1 = form.getTextField('name1');
      formName1.setText(SessionStorage.getItem('installerName'));
      const formName2 = form.getTextField('name2');
      formName2.setText(SessionStorage.getItem('installerName'));
      const formDD1 = form.getTextField('date 1a');
      formDD1.setText(statementData.workFromdd);
      const formMM1 = form.getTextField('date 1b');
      formMM1.setText(statementData.workFrommm);
      const formYY1 = form.getTextField('date 1c');
      formYY1.setText(statementData.workFromyy);
      const formDD2 = form.getTextField('date 2a');
      formDD2.setText(statementData.workTodd);
      const formMM2 = form.getTextField('date 2b');
      formMM2.setText(statementData.workTomm);
      const formYY2 = form.getTextField('date 2c');
      formYY2.setText(statementData.workToyy);
      const formDD4 = form.getTextField('date 3a');
      formDD4.setText(todaydd);
      //formDD4.setText(statementData.invoicedd);
      const formMM4 = form.getTextField('date 3b');
      formMM4.setText(todaymm);
      //formMM4.setText(statementData.invoicemm);
      const formYY4 = form.getTextField('date 3c');
      formYY4.setText(todayyy);
      //formYY4.setText(statementData.invoiceyy);
      const formDD5 = form.getTextField('date 5a');
      formDD5.setText(todaydd);
      const formMM5 = form.getTextField('date 5b');
      formMM5.setText(todaymm);
      const formYY5 = form.getTextField('date 5c');
      formYY5.setText(todayyy);
      if (statementData.noSubcontractor) {
        form.getCheckBox('Check Box1').check();
        const formDD3 = form.getTextField('date 4a');
        formDD3.setText(statementData.insuranceDate.substring(0,2));
        const formMM3 = form.getTextField('date 4b');
        formMM3.setText(statementData.insuranceDate.substring(3,5));
        const formYY3 = form.getTextField('date 4c');
        formYY3.setText(statementData.insuranceDate.substring(8,10));
      }
      else
        form.getCheckBox('Check Box2').check();
      console.log('contractor statement form filled');
      const signImage = await pdfDoc.embedPng(signImageBytes);
      const signDims = signImage.scale(0.25);
      const signPage = pdfDoc.getPage(0);
      signPage.drawImage(signImage, {
        x: signPage.getWidth() - 410 - signDims.width,
        y: signPage.getHeight() - 660 - signDims.height,
        width: signDims.width,
        height: signDims.height,
      })

      //      Save generated form to show user for confirmation

      console.log('contractor statement form signed');
      const pdfBytes = await pdfDoc.saveAsBase64();

      var pdfForm = new FormData();
      pdfForm.append('StatementPdf',new Blob([pdfBytes], {type : 'application/pdf'}),'Signature.pdf');

      axios.post('Services/SaveStatementPdf.aspx', pdfForm, {
        headers: {
          'Content-Type': 'multipart/form-data',
          'UserEmail': SessionStorage.getItem('userEmail'),
          'InstallerId': SessionStorage.getItem('installerId'),
          'SessionKey': SessionStorage.getItem('sessionKey')
        },
      })
      .then(response => {
        //    Show the signed statement for approval
        console.log('statement saved');
        var postResponse = response.data;
        //console.log(postResponse);
        //console.log('result code');
        //console.log(postResponse.resultCode);
        if (postResponse.resultCode != 0) {
          console.log(postResponse.resultCode);
          this.resultMsg = postResponse.resultMsg;
          this.resultType = postResponse.resultType;
          this.resultTitle = postResponse.resultTitle;
          if (postResponse.resultCode == 30) {
            this.sessionTimeout = true;
            //this.nextRoute = '/app/home/submitinvoice'
          }
          this.userMessage = true;
        }
        else {
          this.statementPath = postResponse.filePath;
          //    load the pdf
          this.statementSource = postResponse.pdfURL;
        }
      })
      .catch(error => {
        console.log(error);
        this.resultMsg = 'System error: ' + error.response.status + '. Please contact CCC.';
        this.resultType = 'System Error';
        this.resultTitle = 'System Error';
        //this.nextRoute = '/app/home/submitinvoice'
        this.userMessage = true;
        // set nav
        //var wnd = window.open('about:blank', '', '_blank');
        //wnd.document.write(error.response.data);
      });
      
    },

    submitStatement() {
      //
      //    Submit: update statement status and show invoice list
      //

      console.log('Statement: ' + this.statementPath);
      axios.get('Services/SubmitStatement.aspx', {
        headers: {
          'Content-Type': 'multipart/form-data',
          'UserEmail': SessionStorage.getItem('userEmail'),
          'StatementId': SessionStorage.getItem('statementId'),
          'StatementPath': this.statementPath,
          'InstallerName': SessionStorage.getItem('installerName'),
          'InstallerId': SessionStorage.getItem('installerId'),
          'SessionKey': SessionStorage.getItem('sessionKey')
        },
      })
      .then(response => {
        //    Check result message
        //console.log('statement submitted');
        var postResponse = response.data;
        if (postResponse.resultCode != 10) {
          this.resultMsg = postResponse.resultMsg;
          this.resultType = postResponse.resultType;
          this.resultTitle = postResponse.resultTitle;
          if (postResponse.resultCode == 30) {
            this.sessionTimeout = true;
            //this.nextRoute = '/app/home/submitinvoice'
          }
          this.userMessage = true;
        }
        else {
          //    invoice loaded and statement submitted - show the updated invoice list
        // ************************* update invoice list
          this.showNote('Your invoice and statement have been submitted', 'green', 3500);
          this.$router.replace('/app/home/invoicelist');
        }
      })
      .catch(error => {
        console.log(error);
        this.resultMsg = 'System error: ' + error.response.status + '. Please contact CCC.';
        this.resultType = 'System Error';
        this.resultTitle = 'System Error';
        this.userMessage = true;
      });

    },
  
    checkCancel() {
      //
      //    Cancel selected - confirm
      //
      this.confirmCancel = true;
    },

    cancelInvoice() {
      //
      //    Cancel confirmed: remove invoice and statement files and go back to submit invoice screen
      //

      axios.get('Services/DeleteStatement.aspx', {
        headers: {
          'Content-Type': 'multipart/form-data',
          'UserEmail': SessionStorage.getItem('userEmail'),
          'StatementId': SessionStorage.getItem('statementId'),
          'StatementFile': this.statementPath,
          'DeleteType': 'statement',
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
          this.showNote('Your invoice and statement have not been submitted', 'orange', 3500);
          this.$router.replace('/app/home/submitinvoice');
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
    }

  }
  
}

</script>
