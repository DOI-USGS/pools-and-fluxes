<template>
  <section>
    <div id="chart-container" />
  </section>
</template>
<script>
import * as d3Base from 'd3';
export default {
  name: "PoolFluxChart",
    components: {
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
      svgChart: null,
      chartContainer: null,
      tooltip: null,
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
    
    // define div for tooltip
    // this.tooltip = this.chartContainer
    //   .append("div")
    //   .attr("class", "tooltip")

    // create svg that will hold chart
    this.svgChart = this.chartContainer
      .append("svg")
        .classed("chart", true)
        .attr("viewBox", "0 0 " + (this.chartWidth + this.margin.left + this.margin.right) + " " + (this.chartHeight + this.margin.top + this.margin.bottom))
        .attr("preserveAspectRatio", "xMidYMid meet")
      .append("g")
        .attr("transform","translate(" + this.margin.left + "," + this.margin.top + ")");

    this.loadData();
    },
    methods:{
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
              // .on("mouseover", d => self.populateTooltip(d))					
              // .on("mouseout", d => self.fadeEl(self.tooltip, 0, 50))

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
              // .on("mouseover", d => self.populateTooltip(d))					
              // .on("mouseout", d => self.fadeEl(self.tooltip, 0, 50))

        },
        imagePath(file){
          const image_src = 'https://labs.waterdata.usgs.gov/visualizations/images/' + file
          return image_src

        },
        populateTooltip(d){
          const self = this;

          self.fadeEl(self.tooltip, 0.9)

          // use image_file from this.volume as ending to https://labs.waterdata.usgs.gov/visualizations/images/
          let img_file = self.imagePath(d.image_file)
        
          self.tooltip
            .html("<img src='" + img_file + "' >")
              .attr("class", "popUp")

          self.tooltip.select('img')
            .style("width", "200px")
            .style("height", "200px")

        },
        fadeEl(el, alpha, time_duration = 0){
          el.transition().duration(time_duration).style("opacity", alpha)

        }
    }
}
</script>
<style scoped lang="scss">

#chart-container {
  height: 70vh;
  width: 90vw;
  margin: 1vw;
}
.tooltip {	
    position: fixed;
    text-align: center;			
    width: 220px;				
    max-width: 100px;	
    height: 220px;					
    padding: 2px;				
    border-radius: 8px;			
    z-index: 100;	
    opacity: 0;
    // color: "royalblue";
    // border: "solid";
    // border-width: 1px;
    // border-radius: 5px;
    // padding: 10px;

    img {
      max-width: 100px;
      max-height:100px;
    }
}
</style>