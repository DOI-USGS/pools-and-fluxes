<template>
  <div
    v-show="show"
    tabindex="-1"
    class="overlay"
    role="none presentation"
    @keydown.esc="close"
  >
    <div
      class="dialog"
      role="dialog"
      aria-labelledby="dialogTitle"
    >
      <header
        class="dialog__header"
        :style="{'background-color': color}"
      >
        <h3
          role="none presentation"
          class="dialog__type"
          v-text="type"
        />
      </header>

      <hr class="dialog__break">

      <section class="dialog__content">
        <h2
          id="dialogTitle"
          role="none presentation"
          class="dialog__title"
          v-text="title"
        />
        <p>
          <span
            class="dialog__size_prefix"
            role="none presentation"
            v-text="sizePrefix"
          />
          <span
            class="dialog__size"
            role="none presentation"
          ><a
            role="link"
            :href="dataSource"
            target="_blank"
            v-text="size"
          /></span>
        </p>
        <p
          class="dialog__range"
          v-text="range"
        />
        <p
          id="dialogDefPrefix"
          class="dialog__def_prefix"
          role="none presentation"
          v-text="definitionPrefix"
        />
        <section class="dialog__def_content">
          <picture>
            <source
              :srcset="sourceWebp"
              type="image/webp"
              role="none presentation"
            >
            <source
              :srcset="source"
              type="image/png"
              role="none presentation"
            >
            <a
              role="link"
              :href="imageSite"
              target="_blank"
            >
              <img
                class="dialog__image"
                role="image"
                :src="sourceWebp"
                width="200px"
                height="200px"
                :alt="altText"
              >
            </a>
          </picture>
          <section aria-labelledby="dialogDefPrefix">
            <p
              class="dialog__definition"
              v-text="definition"
            />
          </section>
        </section>
      </section>
    
      <hr
        class="dialog__break"
        role="separator"
      >

      <footer class="dialog__footer">
        <button
          class="button dialog__close"
          @click="close"
        >
          <p>Close</p>
        </button>
      </footer>
    </div>
  </div>
</template>

<script>
export default {
    props: ['show', 'title', 'type', 'color', 'sizePrefix', 'size', 'range', 'dataSource', 'source', 'sourceWebp', 'imageSite', 'definitionPrefix', 'definition', 'close', 'altText']
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
  overflow: hidden;
  margin-left: auto;
  margin-right: auto;
  margin-top: 2.5rem;
  width: 35rem;
  max-width: 90%;
  max-height: 90%;
}
.dialog__break {
  border: 0.5px solid white;
}
.dialog__header {
  color: #ffffff;
  -moz-border-radius: 0.75rem 0.75rem 0rem 0rem;
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
  font-weight: 700;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
}
.dialog__type {
  font-weight: 500;
  line-height: 1.75rem;
  margin-bottom: 0.5rem;
}
.dialog__size_prefix {
  font-weight: 700;
}
.dialog__size {
  line-height: 1rem;
  font-weight: 500;
  padding: 0.25em 0 0 0;
}
.dialog__range {
  line-height: 1rem;
  margin-bottom: 1rem;
  padding: 0.25em 0 0 0;
  color: #6E6E6E;
}
.dialog__range {
  line-height: 1rem;
  margin-bottom: 1rem;
  color: #6E6E6E;
}
.dialog__image {
  float: right;
  margin: 5px;
}
.dialog__def_prefix {
  font-weight: 700;
}
.dialog__def_content {
  min-height: 200px;
}
.dialog__definition {
  line-height: 1.25rem;
  margin-bottom: 0.1rem;
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