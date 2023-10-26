<template>
  <q-page padding>
    <div>
      <h5 class="q-my-md text-orange-9">
        Installer new password
      </h5>
    </div>
    <q-card class="full-width q-mb-md" style="max-width: 350px">
      <q-card-section>
        <q-input @keyup.enter="doEnter" v-model="userEmail" label="email" placeholder="name@example.com" />
        <q-input @keyup.enter="doEnter" v-model="password" filled :type="isPwd ? 'password' : 'text'" label="your new password" hint="at least 8 characters - letters and numbers" >
          <template #append>
            <q-icon
              :name="isPwd ? 'mdi-eye' : 'mdi-eye-off'"
              class="cursor-pointer"
              @click="isPwd = !isPwd"
            />
          </template>
        </q-input>
        <q-input @keyup.enter="doEnter" v-model="password2" filled :type="isPwd2 ? 'password' : 'text'" label="confirm the password">
          <template #append>
            <q-icon
              :name="isPwd2 ? 'mdi-eye' : 'mdi-eye-off'"
              class="cursor-pointer"
              @click="isPwd2 = !isPwd2"
            />
          </template>
        </q-input>
      </q-card-section>
    </q-card>
    <q-btn label="Change Password" class="full-width" style="max-width: 350px" color="orange-8" @click="resetPW"></q-btn>

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
import { SessionStorage } from 'quasar';
import { useQuasar } from 'quasar';
//import globalData from 'src/components/GlobalData.js'

export default {
  setup() {
    
    const $q = useQuasar();
    return {

      showUploadNote (text, colour) {
        $q.notify({
          message: text,
          color: colour,
          timeout: 3500
        })
      }
    }
  },

  data () {

    return {
      userEmail: this.$route.query.UserLogin,
      //userEmail: '',
      resetKey: '',
      password: '',
      password2: '',
      resultMsg: '',
      resultType: '',
      resultTitle: '',
      userMessage: ref(false),
      isPwd: ref(true),
      isPwd2: ref(true),
    }
  },

  methods: {

    // eslint-disable-next-line no-unused-vars
    doEnter(e) {
      this.resetPW();
    },

    resetPW() {

      if (this.password.length < 8) {
        this.resultType = 'Error';
        this.resultMsg = 'Please use at least eight letters and numbers';
        this.resultTitle = 'Password too short';
        this.userMessage = true;
        return;
      }

      if (!this.password.match(/\d/)) {
        this.resultType = 'Error';
        this.resultMsg = 'Please use at least one number in your password';
        this.resultTitle = 'Password needs number';
        this.userMessage = true;
        return;
      }

      if (!this.password.match(/\D/)) {
        this.resultType = 'Error';
        this.resultMsg = 'Please use at least one letter in your password';
        this.resultTitle = 'Password needs letter';
        this.userMessage = true;
        return;
      }

      if (this.password != this.password2) {
          this.resultType = 'Error';
          this.resultMsg = 'The passwords do not match';
          this.resultTitle = 'No Match';
          this.userMessage = true;
        return;
      }

      var resultCode = 0;
      var resultType = '';    //  OK, Error, etc.
      var resultMsg = '';
      var resultTitle = '';

      //  Consume ChangePassword service and check result
      const xhttp = new XMLHttpRequest();
      xhttp.onload = () =>  {
        var resultObj = JSON.parse(xhttp.responseText);
        //console.log(xhttp.response);
        resultCode = parseInt(resultObj.resultCode);
        resultType = resultObj.resultType;
        resultMsg = resultObj.resultMsg;
        resultTitle = resultObj.resultTitle;
        //console.log('Result: ['+resultCode+'], ['+resultMsg+'], ['+resultType+']');
        this.resultType = resultType;
        this.resultMsg = resultMsg;
        this.resultTitle = resultTitle;
        this.userMessage = true;
        if (resultCode == 10) {
          SessionStorage.set('userEmail',this.userEmail);
          this.showUploadNote('Your password has been changed. You can use it to login.','orange');
          this.$router.push('Login');
        }
      }
      const resetKey = this.$route.query.ResetKey;

      xhttp.open("GET", 'Services/ChangePassword.aspx', true);
      xhttp.setRequestHeader('UserEmail', this.userEmail);
      xhttp.setRequestHeader('Password', this.password);
      xhttp.setRequestHeader('ResetKey', resetKey);
      xhttp.send();
    }
  }
}
</script>
