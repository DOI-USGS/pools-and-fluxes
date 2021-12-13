<template>
  <div id="visualization">
    <h2>The volume of water on Earth</h2>
    <Logpile />
  </div>
</template>

<script>

export default {
    name: 'Visualization',
    components: {
      Logpile: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/logpile")
    },
    computed: {
    },
    mounted(){
      
    },
    methods:{
    }
} 
</script>

<style lang="scss">

</style>
