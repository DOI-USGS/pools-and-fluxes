<template>
  <div v-show="show" class="overlay">


    <div class="dialog">

      <div class="dialog__content">
        <h2 class="dialog__title" v-text="title"></h2>
        <h3 class="dialog__type" v-text="type"></h3>
        <p class="dialog__size" v-text="size"></p>
        <img v-bind:src="source" width="200px" height="200px">
        <p class="dialog__definition" v-text="definition"></p>
      </div>
    
      <hr />

      <div class="dialog__footer">
        <button @click="close" class="dialog__close">Close</button>
      </div>

    </div>

  </div>
</template>

<script>
export default {
    props: ['show', 'title', 'type', 'size', 'source', 'definition', 'close']
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
  max-width: 100%;
  width: 24rem;
}
.dialog__content {
  padding-left: 0.75rem;
  padding-right: 0.75rem;
  padding-top: 1rem;
  padding-bottom: 1rem;
}
.dialog__title {
  font-weight: 500;
  font-size: 1.125rem;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
  --tw-text-opacity: 1;
  color: rgba(17, 24, 39, var(--tw-text-opacity));
}
.dialog__type {
  font-weight: 500;
  font-size: 1 rem;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
  --tw-text-opacity: 1;
  color: rgba(17, 24, 39, var(--tw-text-opacity));
}
.dialog__size {
  font-size: 0.875rem;
  line-height: 1.25rem;
  margin-bottom: 1rem;
  --tw-text-opacity: 1;
  color: rgba(107, 114, 128, var(--tw-text-opacity));
}
.dialog__definition {
  font-size: 0.875rem;
  line-height: 1.25rem;
  margin-bottom: 1rem;
  --tw-text-opacity: 1;
  color: rgba(107, 114, 128, var(--tw-text-opacity));
}
.dialog__footer {
  display: flex;
  justify-content: flex-end;
  padding-top: 1rem;
  padding-bottom: 1rem;
}
.dialog__close {
  border-radius: 0.75rem;
  font-weight: 500;
  margin-right: 1rem;
}
.dialog__close:focus{
  outline: 2px solid transparent;
  outline-offset: 2px;
}
.dialog__close{
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
  padding-left: 1rem;
  padding-right: 1rem;
}
.dialog__close:focus{
  --tw-ring-offset-shadow: var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);
  --tw-ring-shadow: var(--tw-ring-inset) 0 0 0 calc(2px + var(--tw-ring-offset-width)) var(--tw-ring-color);
  box-shadow: var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000);
  --tw-ring-opacity: 1;
  --tw-ring-color: rgba(75, 85, 99, var(--tw-ring-opacity));
  --tw-ring-opacity: 0.5;
}
.dialog__close{
  --tw-text-opacity: 1;
  color: rgba(17, 24, 39, var(--tw-text-opacity));
  -webkit-user-select: none;
     -moz-user-select: none;
      -ms-user-select: none;
          user-select: none;
}
.dialog__close:hover {
  --tw-text-opacity: 1;
  color: rgba(55, 65, 81, var(--tw-text-opacity));
}
</style>