<template>
  <q-page padding>
    <q-toolbar class="bg-blue-5 text-white">
      <q-toolbar-title v-if="signatureType === 'statement'" style="font-size: 1.1rem">Sign your Contractor Statement below</q-toolbar-title>
      <q-toolbar-title v-else style="font-size: 1.1rem">Write your signature below</q-toolbar-title>
    </q-toolbar>
    <div class="q-mt-lg"></div>
    <div id="SignPad" class="signature-pad" style="background-color: white; border: 1px solid orange; margin: auto; width: 306px;">
      <!-- <div class="signature-pad--body"> -->
        <canvas id="SignCanvas" class="q-ma-xs"></canvas>
      <!-- </div> -->
    </div>
    <div class="signature-pad--footer">
      <div class="row q-mt-lg">
        <div class="col-6 q-px-xs">
          <q-btn v-if="signatureType === 'statement'" label="Sign" class="full-width" color="primary" @click="signStatement"></q-btn>
          <q-btn v-else label="Save" class="full-width" color="primary" @click="saveSignature"></q-btn>
        </div>
        <div class="col-6 q-px-xs">
          <q-btn v-if="signatureType === 'statement'" label="Cancel" class="full-width" color="orange-8" @click="cancelSignature"></q-btn>
          <q-btn v-else label="Clear" class="full-width" color="orange-8" @click="clearSignature"></q-btn>
        </div>
      </div>
    </div>
  </q-page>
</template>

<!-- error dialog -->

<script>
import { SessionStorage } from 'quasar';
import SignaturePad from "signature_pad";
import axios from 'axios';

export default {
  setup() {
  },


  data () {
    return {
      signaturePad: null,
      signatureData: null,
      signatureType: null
    }
  },

  created () {
    //console.log('created');

  },

  mounted() {
    console.log('SignPad mounted');
    //console.log(this.signatureData);
    const canvas = document.getElementById('SignCanvas');
    this.signaturePad = new SignaturePad(canvas);
    var signatureStatus = SessionStorage.getItem('signatureStatus');
    var signatureSource = SessionStorage.getItem('signatureSource');      //    Set in Login.vue or passed from Statement.vue
    if (signatureSource == 'menu') {
      this.signatureType = 'general';
    }
    else {
      this.signatureType = 'statement';
    }

    //alert('here');
    //var context = this;
    //    Get saved signature, if any (status of 'none' indicates that it has already been determined that the installer has no signature)
    if (signatureStatus != 'none') {
      this.getSignature();
    }

  },

  methods: {

    async getSignature() {
      console.log('getting signature');
      var response = await fetch('/CEPWeb/CEPdata/Signatures/Signature-' + SessionStorage.getItem('installerId') + '.json');
      console.log(response.status); // 200
      console.log(response.statusText); // OK
      if (response.status === 200) {
        // var context = this;
        var signatureData = await response.json();
        console.log('signature');
        console.log(signatureData);
        this.signaturePad.fromData(signatureData);
      }
    },

    saveSignature() {
      //var data = this.signaturePad.toData();
      if (this.signaturePad.isEmpty()) {
        alert("Please write your signature first.");
      }
      else {
        //var dataURL = this.signaturePad.toDataURL("image/jpeg");
        const canvas = document.getElementById("SignCanvas");

        var dataURL = canvas.toDataURL("image/png");
        var pngData = dataURL.split(';base64,')[1];

        var signatureData = this.signaturePad.toData();

        var signatureForm = new FormData();
        //signatureData.append("SignatureImage",dataURL,"Signature.jpg");
        //var blobArray = [pngData];
        signatureForm.append("SignatureImage",new Blob([pngData], {type : "image/png"}),"Signature.png");
        signatureForm.append("SignatureImage",new Blob([JSON.stringify(signatureData)], {type : "text/plain"}),"Signature.dat");
        //signatureForm.append("SignatureData",JSON.stringify(signatureData));     // *********** second post
        //signatureData.append(data);

        axios.post('Services/SaveSignature.aspx', signatureForm, {
            headers: {
                'Content-Type': 'multipart/form-data',
                'InstallerId': SessionStorage.getItem('installerId'),
                'UserEmail': SessionStorage.getItem('userEmail'),
                'SessionKey': SessionStorage.getItem('sessionKey')
            },
          }
        ).then(function(){
          console.log('signature saved');
          SessionStorage.set('signatureStatus','saved');
        })
        .catch(error => {
          alert('error saving signature: ' + error.response.status );
          var wnd = window.open("about:blank", "", "_blank");
          wnd.document.write(error.response.data);
          //alert('error saving signature: ' + error.response.status + ' ' + error.response.data);
        });

      }
    },

    clearSignature() {
      this.signaturePad.clear();
    },

    signStatement() {
      console.log('signing A');
      this.saveSignature();   // ************** await??
      console.log('signing B');

      SessionStorage.set('signatureSource','menu');
      SessionStorage.set('signatureStatus','saved');  // ************** await??
      console.log('signing C');
      this.$router.replace('/app/showstatement');
    },

    cancelSignature() {
      SessionStorage.set('signatureSource','menu');
      this.$router.replace('/app/home/submitinvoice');
    }

  }
}
</script>
