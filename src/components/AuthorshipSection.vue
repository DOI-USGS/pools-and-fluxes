<template>
  <VizSection
    id="authors"
    :figures="false"
    :fig-caption="false"
  >
    <!-- HEADING -->
    <template #heading>
      <h1
        v-if="titleLevel === '1'"
        v-html="authors.title"
      />
      <h2
        v-if="titleLevel === '2'"
        v-html="authors.title"
      />
      <h3
        v-if="titleLevel === '3'"
        v-html="authors.title"
      />
    </template>
    <template #aboveExplanation>
      <p v-html="formatAuthorText(authors)" />
    </template>
  </VizSection>
</template>

<script setup>
  import VizSection from '@/components/VizSection.vue';

  // define props
  defineProps({
    titleLevel: {
      type: String,
      default: "2"
    },
    authors: {
      type: Object,
      // Object or array defaults must be returned from
      // a factory function.
      default() {
        return {
          title: "USGS Vizlab",
          authorText: "",
          projectTeam: [],
          leadAuthors: [],
          additionalAuthors: [],
          lastAuthor: []
        }
      }
    },
  })


  function createLink(data) {
    if (!data || !data.name) {
      return '';
    }
    return data.link
      ? `<a href="${data.link}" target="_blank" rel="noopener noreferrer">${data.name}</a>`
      : data.name;
  }

  function formatAuthorText(data) {
    const projectTeam = Array.isArray(data?.projectTeam) ? data.projectTeam : [];
    const leadAuthors = Array.isArray(data?.leadAuthors) ? data.leadAuthors : [];
    const additionalAuthors = Array.isArray(data?.additionalAuthors) ? data.additionalAuthors : [];
    const lastAuthor = Array.isArray(data?.lastAuthor) ? data.lastAuthor : [];
    const authorText = typeof data?.authorText === 'string' ? data.authorText : '';

    // Map placeholders to their replacement text
    const replacements = {
      "{projectTeam}": createLink(projectTeam[0]),
      "{leadAuthors}": leadAuthors.length > 2 ? `${leadAuthors.slice(0, leadAuthors.length - 1).map(createLink).join(', ')}, and ${leadAuthors.slice(-1).map(createLink)}` : leadAuthors.map(createLink).join(' and '),
      "{additionalAuthors}": additionalAuthors.map(createLink).join(', '),
      "{lastAuthor}": createLink(lastAuthor[0])
    };
    
    // Replace placeholders in the authorText
    return authorText.replace(/{\w+}/g, (match) => {
      return replacements[match] || match; // Return the replacement or the original text if not found
    });
  }

</script>

<style>
</style>
