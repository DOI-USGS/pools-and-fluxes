<template>
  <div id="visualization">
    <h2>Pools and Fluxes in the Water Cycle</h2>
    <Logpile />
    <p>
      This visualization was inspired by the <a href="https://www.duncangeere.com/carbonincontext/" target="_blank">Carbon in Context</a> logpile chart by Duncan Geere. The magnitude of water cycle components are from <a href="https://www.nature.com/articles/s41561-019-0374-y" target="_blank">Abbott et al. (2019) Human domination of the global water cycle absent from depictions and perceptions.</a>  
    </p>
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
#visualization {
  margin: 2.5%;
  width: 95%;
}
</style>
