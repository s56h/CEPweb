<template>
  <q-page padding>
    <q-toolbar class="bg-primary text-white shadow-2">
        <q-toolbar-title>Contact Us</q-toolbar-title>
    </q-toolbar>
    <q-list bordered>
      <q-item-label header class="text-deep-orange-9 text-weight-bold">Address</q-item-label>
      <q-item class="q-my-xs">
        <q-item-section class="col-3">
          <q-icon name="mdi-map-marker-outline" color="orange-6" style="font-size: 2em;" />
        </q-item-section>

        <q-item-section class="col-9">
          <q-item-label>Head Office</q-item-label>
          <q-item-label caption lines="1">59 Prince William Drive</q-item-label>
          <q-item-label caption lines="1">Seven Hills NSW 2147</q-item-label>
        </q-item-section>

      </q-item>
      <q-separator />

      <q-item-label header class="text-deep-orange-9 text-weight-bold">Phone</q-item-label>
      <q-item class="q-my-xs">
        <q-item-section class="col-3">
          <q-icon name="mdi-phone" color="orange-6" style="font-size: 2em;" />
        </q-item-section>

        <q-item-section class="col-9">
          <q-item-label>(02) 9674 6655</q-item-label>
        </q-item-section>
      </q-item>
      <q-separator />
       
      <q-item-label header class="text-deep-orange-9 text-weight-bold">Hours</q-item-label>
      <q-item class="q-my-xs">
        <q-item-section class="col-3">
          <q-icon name="mdi-clock" color="orange-6" style="font-size: 2em;" />
        </q-item-section>

        <q-item-section class="col-9">
          <q-item-label>8am – 4pm Mon-Fri</q-item-label>
        </q-item-section>
      </q-item>
     
    </q-list>
  </q-page>
</template>

<script>
export default {
}
</script>
