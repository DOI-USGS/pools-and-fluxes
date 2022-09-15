<template>
  <section>
    <div id="page-content">
      <dialogCard :show="showDialog" :title="cardTitle" :type="cardType" :source="cardImageSource" :size="cardFeatureSize" :definition="cardFeatureDefinition" :close="close"/>
      <div id="chart-container" />
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
export default {
  name: "PoolFluxChart",
    components: {
      dialogCard: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/dialog")
    },
    data() {
    return {
      publicPath: process.env.BASE_URL, // this is need for the data files in the public folder, this allows the application to find the files when on different deployment roots
      d3: null,

      // dimensions
      w: null,
      h: null,
      margin: { top: 10, right: 25, bottom: 20, left: 200 },
      chartWidth: null,
      chartHeight: null,
      svg: null,
      svgChart: null,
      chartContainer: null,
      tooltip: null,
      showDialog: false,
      cardTitle: null,
      cardFeatureSize: null,
      cardImageSource: null,
      cardFeatureDefinition: null,
      cardType: null
      }
  },
  mounted(){      
      this.d3 = Object.assign(d3Base);

    // chart elements
    this.w = document.getElementById("chart-container").offsetWidth;
    this.h = document.getElementById("chart-container").offsetHeight;
    this.chartWidth = this.w - this.margin.left - this.margin.right;
    this.chartHeight = this.h - this.margin.top - this.margin.bottom;
    this.chartContainer = this.d3.select("#chart-container")

    // create svg that will hold chart
    this.svg = this.chartContainer
      .append("svg")
        .classed("chart", true)
        .attr("viewBox", "0 0 " + (this.chartWidth + this.margin.left + this.margin.right) + " " + (this.chartHeight + this.margin.top + this.margin.bottom))
        .attr("preserveAspectRatio", "xMidYMid meet")
    this.svgChart = this.svg.append("g")
        .attr("transform","translate(" + this.margin.left + "," + this.margin.top + ")")
        .attr("id", "pool-flux-chart");

    this.loadData();
    },
    methods:{
        close() {
          console.log('close')
          this.showDialog = false;
        },
        loadData(){
            const self = this;

            // read in data
            let promises = [
                self.d3.csv(self.publicPath + "data/pools-fluxes-examples-limited.csv", this.d3.autoType) //self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/abbott_pools_and_fluxes_images.csv", this.d3.autoType)
            ];
            Promise.all(promises).then(self.callback);
        },
        callback(data){
          const self = this;

          // pools and fluxes of water
          this.volume = data[0];
          console.log(this.volume)

          // draw chart
          this.addChart(this.volume)

        },
        addChart(data){
          this.drawChart(data, {
            x: d => d.value_km_3,
            type: this.d3.scaleLog,
            y_pos: 100,
            x_min: 1, // necessary for log
            let_class: 'pool'
          })
        },
        drawChart(data, {
          value = d => d, // convenience alias for x
          x = value, // given d in data, returns value
          type = this.d3.scaleLinear, // takes any scale 
          x_min,
          y_pos,
          y_height = 50,
          let_class
        } = {}) {

          const self = this;

          // x axis scale
          const xScale = type()
            .domain([x_min, this.d3.max(data, x)])
            .range([0, this.chartWidth])

          this.svgChart.append("g")
            .attr("transform", "translate(0," + this.chartHeight + ")")
            .call(this.d3.axisBottom(xScale))

          // y axis scale for lollipop chart
          const yScale = this.d3.scaleBand()
            .range([0, this.chartHeight])
            .domain(data.map(function(d) { return d.feature }))
            .padding(1);

          this.svgChart.append("g")
            .call(this.d3.axisLeft(yScale))

          // add lollipop lines
          this.svgChart.selectAll("chartLines")
            .data(data)
            .enter()
            .append("line")
              .attr("x1", function(d) { return xScale(x(d)); })
              .attr("x2", x(0))
              .attr("y1", function(d) { return yScale(d.feature); })
              .attr("y2", function(d) { return yScale(d.feature); })
              .style("stroke", "grey")

          // Add lollipop circles
          this.svgChart.selectAll("chartCircles")
            .data(data)
            .enter()
            .append("circle")
              .attr("cx", function(d) { return xScale(x(d)); })
              .attr("cy", function(d) { return yScale(d.feature); })
              .attr("r", "3")
              .style("fill", function(d) {
                switch (d.type) {
                  case 'Pool':
                    return "red";
                    break;
                  case 'Flux':
                    return "blue";
                    break;
                  case 'Example':
                    return "grey";
                    break;
                }
              })
              .attr("stroke", "white")
          
          // Append rectangle that are the width of the chart that we can use to trigger interaction
          let svgInteractionGroup = this.svg.append("g")
            .attr("id", "interaction-container")

          svgInteractionGroup.selectAll("interactionRectangle")
            .data(data)
            .enter()
            .append("rect")
            .attr("class", d => "interactionRectangle " + d.feature)
            .attr("x", 0)
            .attr("y", d => yScale(d.feature))
            .attr("width", this.chartWidth + this.margin.left + this.margin.right)
            .attr("height", this.chartHeight/data.length) //yScale.bandwidth() should work but returns 0
            .style("fill", "white")
            .style("opacity",0)
            .on("click", d => self.populateTooltip(d))

        },
        imagePath(file){
          const image_src = 'https://labs.waterdata.usgs.gov/visualizations/images/' + file
          return image_src

        },
        populateTooltip(d){
          const self = this;

          // Populate card with information
          this.cardTitle = d.feature;
          this.cardType = d.type;
          this.cardFeatureSize = this.d3.format(',')(d.value_km_3) + ' ' +  d.units
          // use image_file from this.volume as ending to https://labs.waterdata.usgs.gov/visualizations/images/
          this.cardImageSource = self.imagePath(d.image_file)
          this.cardFeatureDefinition = d.definition
          this.showDialog = true;

        }
    }
}
</script>
<style scoped lang="scss">
#page-content {
  display: block;
}
#chart-container {
  height: 70vh;
  width: 90vw;
  margin-bottom: 5vw;
}
</style>