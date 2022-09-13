<template>
  <div id="visualization">
    <h2>Pools and Fluxes in the Water Cycle</h2>
    <PoolFluxChart />
    <p>
      Data are adapted from <a href="https://www.nature.com/articles/s41561-019-0374-y" target="_blank">Abbott et al. (2019) Human domination of the global water cycle absent from depictions and perceptions.</a>  
    </p>
  </div>
</template>

<script>

export default {
    name: 'Visualization',
    components: {
      PoolFluxChart: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/pool_flux_chart")
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
