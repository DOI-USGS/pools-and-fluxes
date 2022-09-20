<template>
  <div v-show="show" class="overlay">


    <div class="dialog">
      <div class="dialog__header" background-color="color">
        <h3 class="dialog__type" v-text="type"></h3>
      </div>

      <hr />

      <div class="dialog__content">
        <h2 class="dialog__title" v-text="title"></h2>
        <p class="dialog__size" v-text="size"></p>
        <p class="dialog__range" v-text="range"></p>
        <picture>
          <source v-bind:srcset="sourceWebp" type="image/webp">
          <source v-bind:srcset="source" type="image/png">
          <img v-bind:src="sourceWebp" width="200px" height="200px" v-bind:alt="altText">
        </picture>
        <p class="dialog__definition" v-text="definition"></p>
      </div>
    
      <hr />

      <div class="dialog__footer">
        <button @click="close" class="button dialog__close">Close</button>
      </div>

    </div>

  </div>
</template>

<script>
export default {
    props: ['show', 'title', 'type', 'color', 'size', 'range', 'source', 'sourceWebp', 'definition', 'close', 'altText']
}
</script>
<style>

.overlay {
  --tw-bg-opacity: 1;
  background-color: rgba(0, 0, 0, var(--tw-bg-opacity));
  --tw-bg-opacity: 0.5;
  height: 100%;
  position: fixed;
  top: 0px;
  right: 0px;
  bottom: 0px;
  left: 0px;
  width: 100%;
  z-index: 10;
}
.dialog {
  --tw-bg-opacity: 1;
  background-color: rgba(255, 255, 255, var(--tw-bg-opacity));
  border-radius: 0.75rem;
  margin-left: auto;
  margin-right: auto;
  margin-top: 2.5rem;
  max-width: 90%;
  width: 24rem;
}
.dialog__header {
  padding-left: 0.75rem;
  padding-right: 0.75rem;
  padding-top: 0.25rem;
  padding-bottom: 0.25rem;
}
.dialog__content {
  padding-left: 0.75rem;
  padding-right: 0.75rem;
  padding-top: 1rem;
  padding-bottom: 1rem;
}
.dialog__title {
  font-weight: 500;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
}
.dialog__type {
  font-weight: 500;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
}
.dialog__size {
  line-height: 1rem;
  font-weight: 500;
}
.dialog__range {
  line-height: 1rem;
  margin-bottom: 1rem;
  color: #6E6E6E;
}
.dialog__definition {
  line-height: 1.25rem;
  margin-bottom: 0.25rem;
}
.dialog__footer {
  display: flex;
  justify-content: flex-end;
  padding-top: 0.05rem;
  padding-bottom: 0.05rem;
}
.dialog__close {
  border-radius: 0.75rem;
  font-weight: 400;
  margin-right: 1rem;
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
  padding-left: 1rem;
  padding-right: 1rem;
  --tw-text-opacity: 1;
  color: #6E6E6E;
  -webkit-user-select: none;
     -moz-user-select: none;
      -ms-user-select: none;
          user-select: none;
}
.dialog__close:hover {
  --tw-text-opacity: 1;
  color: rgba(55, 65, 81, var(--tw-text-opacity));
  color: black;
  font-weight: 500;
}
</style>