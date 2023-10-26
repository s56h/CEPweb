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

    <q-footer>   <!--   Footer   -->
      <div>
        <span class="float-right text-caption text-orange-4">v{{appVersion}}</span>
      </div>
    </q-footer>

    <q-page-container>
      <router-view />
    </q-page-container>

  </q-layout>
</template>

<script>
//import { version } from '../../package';
import { SessionStorage } from 'quasar';

export default {
  setup () {

    var version = '1.1.1';
    SessionStorage.clear();
    SessionStorage.set('appVersion',version);

    return {
      appVersion: version,
    }
  }

}

</script>