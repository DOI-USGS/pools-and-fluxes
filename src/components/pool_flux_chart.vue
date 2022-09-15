<template>
  <section>
    <div id="chart-container" class="chart-area">
      <form class="controls">
        Scale:
        <label><input type="radio" name="x-scale" value="log" checked> log </label>
        <label><input type="radio" name="x-scale" value="linear"> linear </label>          
      </form>
    </div>
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
      scales: null,
      xScale: null,
      xAxis: null,
      domXAxis: null,
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
    
    //define scale options
    this.scales = {
      log:  this.d3.scaleLog().base(10),
      linear: this.d3.scaleLinear()            
    },

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
          // console.log(this.volume)

          // customize each x scale
          this.adaptScales(this.volume, 1);

          // set starting x scale
          this.setXScale();
          
          // draw chart
          this.drawChart(this.volume, 1)

          // set up radio button interaction
          this.chartContainer.selectAll("input").on("click", this.changeXScale.bind(this));
          
        },
        adaptScales(data, xMin) {
          Object.keys(this.scales).forEach(function (scaleType) {
              this.scales[scaleType]
                  .domain([xMin, this.d3.max(data, d => d.value_km_3)])
                  .range([0, this.chartWidth]);
          }, this);
        },
        setXScale() {
          let scaleType;
          
          scaleType = this.d3.select('input[name="x-scale"]:checked').node().value;
          this.xScale = this.scales[scaleType];
        },
        drawChart(data, xMin) {

          const self = this;

          this.xAxis = this.d3.axisBottom()
            .scale(self.xScale)

          this.domXAxis = this.svgChart.append("g")
            .attr("transform", "translate(0," + this.chartHeight + ")")
            .call(this.xAxis)

          // y axis scale for lollipop chart
          const yScale = this.d3.scaleBand()
            .range([0, this.chartHeight])
            .domain(data.map(d => d.feature_label))
            .padding(1);

          this.svgChart.append("g")
            .call(this.d3.axisLeft(yScale))

          // add lollipop lines
          this.svgChart.selectAll("chartLine")
            .data(data)
            .enter()
            .append("line")
              .attr("x1",  d => self.xScale(d.value_km_3))
              .attr("x2", self.xScale(xMin))
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("class", d => "chartLine " + d.type)
              .attr("id", d => d.feature_class)
              // .on("mouseover", d => self.populateTooltip(d))					
              // .on("mouseout", d => self.fadeEl(self.tooltip, 0, 50))

          // Add lollipop circles
          this.svgChart.selectAll("chartCircle")
            .data(data)
            .enter()
            .append("circle")
              .attr("cx", d => self.xScale(d.value_km_3))
              .attr("cy", d => yScale(d.feature_label))
              .attr("r", "3")
              .attr("class", d => "chartCircle " + d.type)
              .attr("id", d => d.feature_class)
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
        changeXScale() {
          this.setXScale();
          this.redraw();
        },
        redraw() {
          const self = this;
          
          const animationDuration = 400;

          this.domXAxis.transition()
              .duration(animationDuration)
              .call(self.xAxis.scale(this.xScale));
          this.svgChart.selectAll(".chartCircle")
            .transition()
            .duration(animationDuration)
            .attr("cx", d => self.xScale(d.value_km_3))
          this.svgChart.selectAll(".chartLine")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.value_km_3))
    },
    }
}
</script>
<style scoped lang="scss">

#chart-container {
  height: 70vh;
  width: 90vw;
  margin-top: 1vh;
  margin-bottom: 2vh;
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
<style lang="scss">
$poolColor: #bf8508;
$fluxColor: #0aa687;
$neutralGrey: #919191;
.chartLine {
  stroke-width: 1px;
}
.pool {
  fill: $poolColor;
  stroke: $poolColor;
}
.flux {
  fill: $fluxColor;
  stroke: $fluxColor;
}
.example {
  fill: $neutralGrey;
  stroke: $neutralGrey;
}
</style>