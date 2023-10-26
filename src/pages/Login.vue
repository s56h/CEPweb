<template>
  <q-page padding>
    <div>
      <h5 class="q-my-md text-orange-9">
        Installer log in
      </h5>
    </div>
    <q-card class="full-width q-mb-md" style="max-width: 350px">
      <q-card-section>
        <q-input @keyup.enter="doEnter" v-model="userEmail" label="email" placeholder="name@example.com" />
        <q-input @keyup.enter="doEnter" v-model="password" :type="isPwd ? 'password' : 'text'" label="password" >
          <template #append>
            <q-icon
              :name="isPwd ? 'mdi-eye' : 'mdi-eye-off'"
              class="cursor-pointer"
              @click="isPwd = !isPwd"
            />
          </template>
        </q-input>
      </q-card-section>

    <q-inner-loading
        :showing="showWait"
        label="Please wait..."
        label-class="text-teal"
        label-style="font-size: 1.1em"
      />

    </q-card>
    <q-btn label="log in" class="full-width" style="max-width: 350px" color="orange-8" @click="loginCheck"></q-btn>
    <div class="text-blue q-pt-md" clickable @click="forgotPW" style="cursor:pointer">Forgot your password?</div>
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
          <q-btn flat label="OK" color="orange-9" v-close-popup />
        </q-card-actions>

      </q-card>
    </q-dialog>
    
  </q-page>
</template>

<script>
import { ref } from 'vue';
import { useQuasar } from 'quasar';
import { SessionStorage } from 'quasar';

export default {
  setup() {
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
      userEmail: '',
      password: '',
      resultMsg: '',
      resultType: '',
      resultTitle: '',
      userMessage: false,
      isPwd: ref(true),
      showWait: ref(false),
      waitMessage: ''
    }
  },

  mounted() {
    this.userEmail = SessionStorage.getItem('userEmail');
    SessionStorage.set('signatureStatus','unknown');
    SessionStorage.set('signatureSource','menu');
  },

  methods: {

    // eslint-disable-next-line no-unused-vars
    doEnter(e) {
      this.loginCheck();
    },

    loginCheck() {
      //
      //    Check the user and password
      //    - if OK, navigate to the checklist (sending data)
      //
      var resultCode = 0;
      if (this.password.trim() === '') {
        this.resultType = 'Error';
        this.resultMsg = 'Please enter your password';
        this.resultTitle = 'Password needed';
        this.userMessage = true;
        return;
      }
      if (!this.userEmail) {
        this.resultType = 'Error';
        this.resultMsg = 'Please enter your email';
        this.resultTitle = 'Email needed';
        this.userMessage = true;
        return;
      }
      const xhttp = new XMLHttpRequest();
      xhttp.onload = () => {
        this.showWait = false;
        if (xhttp.status != 200) {
          this.resultMsg = 'System error (code ' + xhttp.status + ')';
          this.resultType = 'System Error';
          this.resultTitle = 'System Error';
          this.userMessage = true;
          return;
        }
        var resultObj = JSON.parse(xhttp.response);
        //console.log(resultObj);
        resultCode = parseInt(resultObj.resultCode);
        //    Show error/message results
        this.resultType = resultObj.resultType;
        if (resultCode != 0) {
          this.resultMsg = resultObj.resultMsg;
          this.resultTitle = resultObj.resultTitle;
          this.userMessage = true;
          if (resultCode != 10)
            return;
        }
        if (resultObj.environment == 'test') {
          this.showNote ("You have logged in to the Test environment","orange",3000)
        }
        SessionStorage.set('environment',resultObj.environment);

        if (this.resultType != 'Error' && this.resultType != 'System Error') {   //  Login OK
          //  get checklist data and save
          SessionStorage.set('userEmail',this.userEmail);
          SessionStorage.set('sessionKey',resultObj.sessionKey);
          SessionStorage.set('installerId',resultObj.installer.installerId);
          SessionStorage.set('installerCompanyId',resultObj.installer.installerCompanyId);
          SessionStorage.set('installerName',resultObj.installer.contactName);
          //SessionStorage.set('loginState',true);

          //V1.2 this.$router.push('/app/home/invoicelist');
          this.$router.push('/app/home');
        }
      }
      xhttp.open('GET', 'Services/CheckLogin.aspx', true);
      xhttp.setRequestHeader('UserEmail', this.userEmail);
      xhttp.setRequestHeader('Password', this.password);
      xhttp.setRequestHeader('Device', 'device: ' + window.innerWidth + 'x' + window.innerHeight);
      this.showWait = true;
      this.waitMessage = 'Logging in...';
      xhttp.send();

    },

    forgotPW() {
      //
      //    Send the reset password email
      //
      if (!this.userEmail) {
        this.resultType = 'Error';
        this.resultMsg = 'Please enter your email';
        this.resultTitle = 'Email needed';
        this.userMessage = true;
        return;
      }

      //console.log('Resetting password for: '+this.userEmail);
      var resultCode = 0;
      const xhttp = new XMLHttpRequest();
      xhttp.onload = () => {
        //console.log("Send email result");
        //console.log(xhttp.response);
        var resultObj = JSON.parse(xhttp.response);
        //console.log(resultObj);
        resultCode = parseInt(resultObj.resultCode);
        this.showWait = false;
        //    Show error/message results
        if (resultCode != 0) {
          this.resultMsg = resultObj.resultMsg;
          this.resultType = resultObj.resultType;
          this.resultTitle = resultObj.resultTitle;
          this.userMessage = true;
        }
      }
      xhttp.open('GET', 'Services/SendResetEmail.aspx', true);
      xhttp.setRequestHeader('UserEmail', this.userEmail);
      this.showWait = true;
      this.waitMessage = 'Sending email...';
      xhttp.send();
    }
  }
}
</script>
