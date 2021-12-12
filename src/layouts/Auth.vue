<template>

  <q-layout view="hHh lpR fFf">

    <q-header elevated>
      <q-toolbar class="bg-grey-1">
        <q-toolbar-title>
          <div class="q-pt-md row">
            <q-img no-spinner fit="scale-down" height="50px" src="~assets/Commercial-flooring-sydney.png" />
          </div>
        </q-toolbar-title>
      </q-toolbar>
    </q-header>

    <q-page-container>
      <router-view />
    </q-page-container>

  </q-layout>
</template>

<script>

//import globalData from 'src/components/GlobalData.js'
import { SessionStorage } from 'quasar';

export default {
  mounted () {
    //
    //    Look for password reset data stored in ASP session
    //    - if present, navigate to reset password page
    //    - otherwise, navigate to login page
    //
    const xhttp = new XMLHttpRequest();
    xhttp.onload = () => {
      var resultObj = JSON.parse(xhttp.response);
      //console.log(resultObj);
      SessionStorage.set('userEmail',resultObj.email);      //  used by Login/ChangePW page
      if (resultObj.resetKey == '') {   //  Normal login
        this.$router.push('Login');
      }
      else {   //  Reset password link has been used
        SessionStorage.set('resetKey',resultObj.resetKey);     //  used by ChangePW page
        this.$router.push('ResetPW');
      }
    }
    xhttp.open('GET', 'Services/CheckReset.aspx', true);
    xhttp.send();

  }

}

</script>
<style>

  .bg-image {
    background-image: url(https://cdn.quasar.dev/img/mountains.jpg);
    background-repeat: no-repeat;
    background-size: contain;
  }

</style>