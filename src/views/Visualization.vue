<template>
  <div id="visualization">
    <h1>Pools and Fluxes in the Water Cycle</h1>
    <PoolFluxChart />
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
