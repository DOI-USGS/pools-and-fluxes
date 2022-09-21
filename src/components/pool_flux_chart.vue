<template>
  <section>
    <div id="page-content">
      <h1>Pools and fluxes in the water cycle</h1>
      <h3>Click on any row of the chart to pull up more information</h3>
      <dialogCard 
        :show="showDialog" 
        :title="cardTitle" 
        :type="cardType" 
        :color="cardColor" 
        :source="cardImageSource" 
        :sourceWebp="cardImageSourceWebp" 
        :size="cardFeatureSize" 
        :range="cardFeatureRange" 
        :definition="cardFeatureDefinition" 
        :close="close"
        :altText="altText"
      />
      <div class="ui buttons big">
        <button
          class="ui button toggle"
          @click="toggle"
          :class="[showUncertainty ? 'active' : '']"
          :text="uncertaintyPrompt"
        >{{ uncertaintyPrompt }}</button>
      </div>
      <div id="chart-container" class="chart-area">
        <svg class="chart" />
      </div>
      <div id="caption-container">
        <form class="controls">
          Scale:
          <label><input type="radio" name="x-scale" value="log" checked> log </label>
          <label><input type="radio" name="x-scale" value="linear"> linear </label>          
        </form>
        <p :text="axisExplanation">{{ axisExplanation }}</p>
        <p><span class='poolText' >Pools</span> are places where water is stored, like the ocean. <span class='fluxText'>Fluxes</span> are the ways that water moves between pools, such as evaporation, precipitation, discharge, recharge, or human use.</p>
        <p>The data for this chart are adapted from <a href="https://www.nature.com/articles/s41561-019-0374-y" target="_blank">Abbott et al. (2019) Human domination of the global water cycle absent from depictions and perceptions.</a></p>
        <p>Learn more about the water cycle and see a diagram of the water cycle on the <a href="https://www.usgs.gov/water-cycle" target="_blank">USGS Water Science School website.</a></p>
      </div>
    </div>
  </section>
</template>
<script>
import * as d3Base from 'd3';
import { isMobile } from 'mobile-device-detect';
export default {
  name: "PoolFluxChart",
    components: {
      dialogCard: () => import( /* webpackPreload: true */ /*webpackChunkName: "section"*/ "./../components/dialog")
    },
    data() {
    return {
      publicPath: process.env.BASE_URL, // this is need for the data files in the public folder, this allows the application to find the files when on different deployment roots
      d3: null,
      mobileView: isMobile,

      // dimensions
      w: null,
      h: null,
      margin: null,
      chartWidth: null,
      chartHeight: null,
      svg: null,
      svgChart: null,
      chartContainer: null,
      captionContainer: null,
      scales: null,
      scaleType: null,
      customNumberFormat: null,
      xScale: null,
      xAxis: null,
      domXAxis: null,
      yAxis: null,
      tooltip: null,
      showDialog: false,
      cardTitle: null,
      cardFeatureSize: null,
      cardFeatureRange:  null,
      cardImageSource: null,
      cardImageSourceWebp: null,
      cardFeatureDefinition: null,
      cardType: null,
      cardColor: null,
      altText: null,
      showUncertainty: false,
      uncertaintyPrompt: null,
      axisExplanation: null
      }
  },
  mounted(){      
    this.d3 = Object.assign(d3Base);
    
    // Set starting value for uncertainty prompt
    this.uncertaintyPrompt = "Show ranges for estimates"

    // chart elements
    this.margin = this.mobileView ? { top: 10, right: 40, bottom: 25, left:  10 } : { top: 10, right: 40, bottom: 25, left: 300 }
    this.w = document.getElementById("chart-container").offsetWidth;
    this.h = document.getElementById("chart-container").offsetHeight;
    this.chartWidth = this.w - this.margin.left - this.margin.right;
    this.chartHeight = this.h - this.margin.top - this.margin.bottom;
    this.chartContainer = this.d3.select("#chart-container")
    this.captionContainer = this.d3.select("#caption-container")
    
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
        toggle() {
          this.showUncertainty = !this.showUncertainty;
          if (this.showUncertainty) {
            this.uncertaintyPrompt = 'Hide ranges for estimates'
            this.d3.selectAll('.chartBandBkgd')
              .style("opacity", 1)
            this.d3.selectAll('.chartBand')
              .style("opacity", 0.3)
          } else {
            this.uncertaintyPrompt = 'Show ranges for estimates'
            this.d3.selectAll('.chartBandBkgd')
              .style("opacity", 0)
            this.d3.selectAll('.chartBand')
              .style("opacity", 0)
          }
        },
        close() {
          this.showDialog = false;
        },
        loadData(){
            const self = this;

            // read in data
            let promises = [
                self.d3.csv(self.publicPath + "data/pools-fluxes-examples-limited.csv", this.d3.autoType) // to be repalced with file stored in s3 via pipeline
            ];
            Promise.all(promises).then(self.callback);
        },
        callback(data){
          const self = this;

          // pools and fluxes of water
          this.volume = data[0];

          // define custom number formatting for xAxis linear scale
          let formatBillion = function(x) { return self.d3.format(".1f")(x / 1e9) + "B"; },
              formatMillion = function(x) { return self.d3.format(".0f")(x / 1e6) + "M"; },
              formatThousand = function(x) { return self.d3.format(".0f")(x / 1e3) + "k"; };

          this.customNumberFormat = function(x) {
            let v = Math.abs(x);
            return (v >= .9995e9 ? formatBillion
                : v >= .9995e6 ? formatMillion
                : formatThousand)(x);
          }

          // customize each x scale
          this.adaptScales(this.volume, 1);

          // set starting x scale
          this.setXScale();

          // set starting value for explanation of axis scale in figure caption
          this.setAxisExplanation();
          
          // draw chart
          this.drawChart(this.volume, 1)

          // set up radio button interaction
          this.captionContainer.selectAll("input").on("click", this.changeXScale.bind(this));
          
        },
        adaptScales(data, xMin) {
          Object.keys(this.scales).forEach(function (scaleType) {
              this.scales[scaleType]
                  .domain([xMin, this.d3.max(data, d => d.range_high)])
                  .range([0, this.chartWidth]);
          }, this);
        },
        setXScale() {          
          this.scaleType = this.d3.select('input[name="x-scale"]:checked').node().value;
          this.xScale = this.scales[this.scaleType];
        },
        drawChart(data, xMin) {

          const self = this;

          this.xAxis = this.d3.axisBottom()
            .scale(self.xScale)

          // Set x-axis number format, depending on scale type
          self.setXAxisNumberFormat(this.scaleType, this.mobileView)

          this.domXAxis = this.svgChart.append("g")
            .attr("transform", "translate(0," + this.chartHeight + ")")
            .call(this.xAxis)
            .attr("class", "x_axis")

          // y axis scale for lollipop chart
          const yScale = this.d3.scaleBand()
            .range([0, this.chartHeight])
            .domain(data.map(d => d.feature_label))
            .padding(1);

          this.yAxis = this.svgChart.append("g")
            .call(this.d3.axisLeft(yScale))
            .attr("class", "y_axis")

          // add lollipop lines
          this.svgChart.selectAll("chartLine")
            .data(data)
            .enter()
            .append("line")
              .attr("x1",  d => self.xScale(d.value_km_3))
              .attr("x2", self.xScale(xMin))
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("class", d => "chartLine " + d.type + " " + d.feature_class)
              .attr("id", d => d.feature_class)
              .style("stroke-dasharray", ("1, 3"))
              .style("opacity", 0)

          // add lines for uncertainty bands
          this.svgChart.selectAll("chartBandBkgd")
            .data(data)
            .enter()
            .append("line")
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' })
              .attr("x1",  d => self.xScale(d.range_high))
              .attr("x2", d => self.xScale(d.range_low))
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("class", d => "chartBandBkgd " + d.type)
              .attr("id", d => d.feature_class)
              .style("stroke-width", 12)
              .style("stroke-linecap", "round")
              .style("opacity", 0)
              
              
          this.svgChart.selectAll("chartBand")
            .data(data)
            .enter()
            .append("line")
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' })
              .attr("x1",  d => self.xScale(d.range_high))
              .attr("x2", d => self.xScale(d.range_low))
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("class", d => "chartBand " + d.type)
              .attr("id", d => d.feature_class)
              .style("stroke-width", 12)
              .style("stroke-linecap", "round")
              .style("opacity", 0)
              

          // Add lollipop circles
          this.svgChart.selectAll("chartCircle")
            .data(data)
            .enter()
            .append("circle")
              .attr("cx", d => self.xScale(d.value_km_3))
              .attr("cy", d => yScale(d.feature_label))
              .attr("r", "6")
              .attr("class", d => "chartCircle " + d.type)
              .attr("id", d => d.feature_class)
          
          // Append rectangle that are the width of the chart that we can use to trigger interaction
          let svgInteractionGroup = this.svg.append("g")
            .attr("id", "interaction-container")

          let interactionRectangles = svgInteractionGroup.selectAll("interactionRectangle")
            .data(data)
            .enter()
            .append("rect")
              .attr("class", d => "interactionRectangle " + d.feature_class)
              .attr("x", 1)
              .attr("y", d => yScale(d.feature_label))
              .attr("width", this.chartWidth + this.margin.left + this.margin.right - 2)
              .attr("height", this.chartHeight/data.length) //yScale.bandwidth() should work but returns 0
              .style("fill", "white")
              .style("opacity", 0)
              .on("click", d => self.populateCard(d))

          if (this.mobileView===false) {
            interactionRectangles
              .on("mouseover", function(d) {
                let current_feature = d.feature_class;
                self.mouseoverRect(current_feature)
              })
              .on("mouseout", function(d) {
                let current_feature = d.feature_class;
                self.mouseoutRect(current_feature)
              })
          } else if (this.mobileView===true) {
            this.yAxis.selectAll('text')
              .attr("text-anchor","start")
              .attr("x", 0)
          }

          
        },
        mouseoverRect(current_feature) {
          const self = this;
          this.d3.selectAll('.interactionRectangle')
            .style("opacity", 0.6)
            this.d3.selectAll('.interactionRectangle.' + current_feature)
            .style("opacity", 0)
          this.d3.selectAll(".chartLine." + current_feature)
            .style("opacity", 1)
        },
        mouseoutRect(current_feature) {
          const self = this;
          this.d3.selectAll('.interactionRectangle')
            .style("opacity", 0)
          this.svgChart.selectAll(".chartLine." + current_feature)
            .style("opacity", 0)
        },
        imagePath(file){
          const image_src = 'https://labs.waterdata.usgs.gov/visualizations/images/' + file
          return image_src

        },
        populateCard(d){
          const self = this;

          // Populate card with information
          this.cardTitle = d.feature_label;
          this.cardType = d.type.charAt(0).toUpperCase() + d.type.slice(1);
          switch (d.type) {
            case 'pool':
              this.cardColor = '#bf8508';
              break;
            case 'flux':
              this.cardColor = "#0aa687";
              break;
            case 'example':
              this.cardColor = "#919191";
              break;
          }
          this.cardFeatureSize = 'Estimate: ' + this.d3.format(',')(d.value_km_3) + ' ' +  d.units
          this.cardFeatureRange = 'Range: ' + this.d3.format(',')(d.range_low) + ' - ' + this.d3.format(',')(d.range_high) + ' ' +  d.units
          // use image_file from this.volume as ending to https://labs.waterdata.usgs.gov/visualizations/images/
          this.cardImageSource = self.imagePath(d.image_file)
          this.cardImageSourceWebp = self.imagePath(d.image_file + '?webp')
          //this.cardImageSourceWebp = self.imagePath(d.image_file.substring(0, d.image_file.indexOf('.')) + '.webp')

          this.cardFeatureDefinition = d.definition
          this.showDialog = true;
          this.altText = d.alt_text;

        },
        changeXScale() {
          this.setXScale();
          this.redraw();
          this.setAxisExplanation();
        },
        setAxisExplanation() {
          this.axisExplanation = this.scaleType==='log' ? 
                  'When you move a fixed distance on a log axis, you multiply the starting value by a value of 10.' : 
                  'When you move a fixed distance on a linear axis, you add a fixed value to the starting value.'
        },
        setXAxisNumberFormat(currentScale, currentlyMobile) {
          const self = this;

          if ((currentScale === 'log' ) && (currentlyMobile===false)) {
            this.xAxis
              .ticks(10)
              .tickFormat(d => this.xScale.tickFormat(0, self.d3.format(".1s"))(d).replace("G","B"))
          } else if ((currentScale === 'log' ) && (currentlyMobile===true)) {
            this.xAxis
              .ticks(7)
              .tickFormat(d => this.xScale.tickFormat(0, self.d3.format(".1s"))(d).replace("G","B"))
          } else if ((currentScale === 'linear') && (currentlyMobile===false)) {
            this.xAxis
              .ticks(10)
              .tickFormat(d =>this.customNumberFormat(d))
          }  else if (currentScale === 'linear' && currentlyMobile===true) {
            this.xAxis
              .ticks(6)
              .tickFormat(d =>this.customNumberFormat(d))
          }
        },
        redraw() {
          const self = this;
          
          const animationDuration = 2000;

          // Reset number format for x axis
          self.setXAxisNumberFormat(this.scaleType, this.mobileView)

          this.domXAxis.transition()
              .duration(animationDuration)
              .call(self.xAxis.scale(this.xScale));
          this.svgChart.selectAll(".chartBand")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.range_high))
            .attr("x2", d => self.xScale(d.range_low))
          this.svgChart.selectAll(".chartBandBkgd")
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
  $poolColor: #bf8508;
  $fluxColor: #0aa687;
  $lightestGrey: #949494;
  $darkGrey: #6E6E6E;
  #page-content {
    display: block;
  }
  #chart-container {
    height: 70vh;
    width: 90vw;
    margin-top: 1vh;
    margin-bottom: 2vh;
  }
  #caption-container {
    display: block;
  }
  .poolText {
    color: $poolColor;
    font-weight: 500;
  }
  .fluxText {
    color: $fluxColor;
    font-weight: 500;
  }
  .button {
    --tw-bg-opacity: 1;
    background-color: white;
    border: 0.5px solid $lightestGrey;
    border-radius: 0.25rem;
    margin-left: auto;
    margin-right: 2px;
    margin-top: 0.5rem;
    padding: 5px 8px 5px 8px;;
    max-width: 24rem;
    -webkit-user-select: none; /* Safari */
    -ms-user-select: none; /* IE 10 and IE 11 */
    user-select: none; /* Standard syntax */
  }
  .button:hover {
    background-color: $darkGrey;
    color: white;
  }

</style>
<style lang="scss">
  // Fonts
  @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@200;300;400;600;700;900&display=swap');
  @import url('https://fonts.googleapis.com/css2?family=Assistant:wght@200;300;400;500;600;700;800&display=swap');
  $Cairo: 'Cairo', sans-serif;
  $Assistant: 'Assistant', sans-serif;

  $poolColor: #bf8508;
  $fluxColor: #0aa687;
  $neutralGrey: #919191;
  $lightestGrey: #949494;


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
  .chartLine {
    stroke-width: 1px;
    stroke: $lightestGrey;
  }
  .chartCircle {
    stroke: #ffffff;
  }
  .chartBandBkgd {
    stroke: #ffffff;
  }
  .chartBand {
    opacity: 0.3;
  }
  .y_axis line {
    visibility:hidden;
  }
  .y_axis path {
    visibility:hidden;
  }
  .y_axis text {
    font-size: 1.6em;
    padding: 1em 0 0 0; 
    font-family: $Assistant;
    @media screen and (max-width: 600px) {
        font-size: 1m;
    }
  }
  .x_axis text {
    font-size: 1.3em;
    padding: 1em 0 0 0; 
    font-family: $Assistant;
    @media screen and (max-width: 600px) {
        font-size: 1m;
    }
  }
</style>