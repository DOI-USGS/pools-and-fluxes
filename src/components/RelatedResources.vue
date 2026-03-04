<template>
  <section
    id="related-resources"
    aria-labelledby="related-resources-heading"
    :lang="inEnglish ? 'en' : 'es'"
  >
    <h2
      id="related-resources-heading"
      class="only"
    >
      {{ relatedResourcesHeading }}
    </h2>
    <ul class="control-list no-separators">
      <li class="control-item">
        <span class="control-prefix">{{ relatedResourcesHeading }}:</span>
      </li>
      <li class="control-item">
        <a
          class="button control-action"
          href="https://www.usgs.gov/special-topics/water-science-school/science/water-cycle"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ waterScienceSchoolLabel }}
          <span class="only">{{ opensInNewTabText }}</span>
        </a>
      </li>
      <li class="control-item">
        <a
          class="button control-action"
          href="https://water.usgs.gov/vizlab/water-cycle"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ waterCycleDiagramLabel }}
          <span class="only">{{ opensInNewTabText }}</span>
        </a>
      </li>
    </ul>
  </section>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  inEnglish: {
    type: Boolean,
    required: true
  }
})

const relatedResourcesHeading = computed(() => (props.inEnglish ? 'Related resources' : 'Recursos relacionados'))
const waterScienceSchoolLabel = computed(() => (props.inEnglish ? 'USGS Water Science School' : 'La Escuela de Ciencias del Agua'))
const waterCycleDiagramLabel = computed(() => (props.inEnglish ? 'The Water Cycle' : 'El Ciclo del Agua'))
const opensInNewTabText = computed(() => (props.inEnglish ? 'opens in new tab' : 'se abre en una nueva pestana'))
</script>

<style scoped lang="scss">
.control-action {
  --tw-bg-opacity: 1;
  background-color: white;
  border: 0.5px solid #A9A9A9;
  border-radius: 0.25rem;
  padding: 5px 8px 5px 8px;
  max-width: 24rem;
  box-shadow: 1px 2px 2px hsl(0deg 0% 40% / 0.47);
  text-decoration: none;
  display: inline-block;
}

.control-action:hover,
.control-action:focus-visible {
  background-color: #6E6E6E;
  color: white;
  box-shadow: 3px 6px 6px hsl(0deg 0% 35% / 0.41);
}

@media screen and (max-width: 600px) {
  .control-action:hover,
  .control-action:focus-visible {
    background-color: white;
    color: black;
    box-shadow: 1px 2px 2px hsl(0deg 0% 35% / 0.47);
  }
}
</style>
