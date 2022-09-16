<template>
  <section>
    <div id="page-content">
      <dialogCard :show="showDialog" :title="cardTitle" :type="cardType" :source="cardImageSource" :size="cardFeatureSize" :definition="cardFeatureDefinition" :close="close"/>
      <h3>Click on any row of the chart to pull up more information</h3>
      <div id="chart-container" class="chart-area">
        <svg class="chart" />
        <form class="controls">
          Scale:
          <label><input type="radio" name="x-scale" value="log" checked> log </label>
          <label><input type="radio" name="x-scale" value="linear"> linear </label>          
        </form>
      </div>
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
      margin: { top: 10, right: 30, bottom: 20, left: 200 },
      chartWidth: null,
      chartHeight: null,
      svg: null,
      svgChart: null,
      chartContainer: null,
      scales: null,
      xScale: null,
      xAxis: null,
      domXAxis: null,
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
    
    //define scale options
    this.scales = {
      log:  this.d3.scaleLog().base(10),
      linear: this.d3.scaleLinear()            
    },

    // create svg that will hold chart
    this.svg = this.chartContainer.select('.chart')
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
                  .domain([xMin, this.d3.max(data, d => d.range_high)])
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

          // add lines for uncertainty bands
          this.svgChart.selectAll("chartBand")
            .data(data)
            .enter()
            .append("line")
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' })
              .attr("x1",  d => self.xScale(d.range_high))
              .attr("x2", d => self.xScale(d.range_low))
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("stroke-width", 7)
              .attr("stroke-linecap", "round")
              .attr("class", d => "chartBand " + d.type)
              .attr("id", d => d.feature_class)

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
          
          // Append rectangle that are the width of the chart that we can use to trigger interaction
          let svgInteractionGroup = this.svg.append("g")
            .attr("id", "interaction-container")

          svgInteractionGroup.selectAll("interactionRectangle")
            .data(data)
            .enter()
            .append("rect")
              .attr("class", d => "interactionRectangle " + d.feature_class)
              .attr("x", 0)
              .attr("y", d => yScale(d.feature_label))
              .attr("width", this.chartWidth + this.margin.left + this.margin.right)
              .attr("height", this.chartHeight/data.length) //yScale.bandwidth() should work but returns 0
              .style("fill", "white")
              .style("opacity", 0)
              .on("click", d => self.populateCard(d))

        },
        imagePath(file){
          const image_src = 'https://labs.waterdata.usgs.gov/visualizations/images/' + file
          return image_src

        },
        populateCard(d){
          const self = this;

          // Populate card with information
          this.cardTitle = d.feature_label;
          this.cardType = d.type;
          this.cardFeatureSize = this.d3.format(',')(d.value_km_3) + ' ' +  d.units
          // use image_file from this.volume as ending to https://labs.waterdata.usgs.gov/visualizations/images/
          this.cardImageSource = self.imagePath(d.image_file)
          this.cardFeatureDefinition = d.definition
          this.showDialog = true;

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
          this.svgChart.selectAll(".chartBand")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.range_high))
            .attr("x2", d => self.xScale(d.range_low))
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
  #page-content {
    display: block;
  }
  #chart-container {
    height: 70vh;
    width: 90vw;
    margin-top: 1vh;
    margin-bottom: 2vh;
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
    fill: #ffffff;
    stroke: $poolColor;
  }
  .flux {
    fill: #ffffff;
    stroke: $fluxColor;
  }
  .example {
    fill: #ffffff;
    stroke: $neutralGrey;
  }
</style>