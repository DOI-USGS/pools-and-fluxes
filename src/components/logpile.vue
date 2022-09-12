<template>
  <section>
    <div id="logpile-container" />
  </section>
</template>
<script>
import * as d3Base from 'd3';
export default {
  name: "LogpileChart",
    components: {
    },
    data() {
    return {
      publicPath: process.env.BASE_URL, // this is need for the data files in the public folder, this allows the application to find the files when on different deployment roots
      d3: null,

      // dimensions
      w: null,
      h: null,
      margin: { top: 50, right: 50, bottom: 50, left: 50 },
      chart_width: null,
      chart_height: null,
      svg_chart: null,
      logpile_container: null,
      tooltip: null,
      }
  },
  mounted(){      
      this.d3 = Object.assign(d3Base);

    // chart elements
    this.w = document.getElementById("logpile-container").offsetWidth;
    this.h = document.getElementById("logpile-container").offsetHeight;
    this.chart_width = this.w - this.margin.left - this.margin.right;
    this.chart_height = (this.h*0.3) - this.margin.top - this.margin.bottom;
    this.logpile_container = this.d3.select("#logpile-container")
    
    
    // define div for tooltip
    this.tooltip = this.logpile_container
      .append("div")
      .attr("class", "tooltip")


    // create svg that will hold chart
    this.svg_logpile = this.logpile_container
      .append("svg")
        .classed("logpile-chart", true)
        .attr("viewBox", "0 0 " + (this.chart_width + this.margin.left + this.margin.right) + " " + (this.chart_height + this.margin.top + this.margin.bottom))
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
                self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/abbott_pools_and_fluxes_images.csv", this.d3.autoType),
            ];
            Promise.all(promises).then(self.callback);
        },
        callback(data){
          const self = this;

          // pools and fluxes of water
          // long-form data with columns Type, Category, Feature_group, Feature, 
          // Vol_1000km3,Vol_km3, Vol_m3, Vol_km3_log10, Vol_row, Vol_prefix, row_start, row_end
          // 'row_' variables provide the numeric bounds for each row in logpile
          // Vol_row and Vol_prefix are for positioning (y-axis) and labelling volumes
          this.volume = data[0];
          console.log(this.volume)

          // draw chart
          this.addlogpile(this.volume)

        },
        addlogpile(data){
          // TODO: draw logpile 
          // currently single axis chart
          this.drawChart(data, {
            x: d => d.Vol_km3,
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

          // const x_margin = 20;
          const self = this;

          // x axis scale
          let xScale = type()
            .domain([x_min, this.d3.max(data, x)])
            .range([0, this.chart_width])

          this.svg_logpile.append("g")
            .attr("transform", "translate(0," + this.chart_height + ")")
            .call(this.d3.axisBottom(xScale))

          // let xAxis = this.d3.axisBottom(xScale)

          // let y = this.d3.scaleBand


          // add pools and fluxes
          // this.svg_logpile.append("g")
          //   .attr("transform", "translate(" + 0 + ", " + y_pos + ")")
          //   .attr("class", "x-axis")
          //   .call(xAxis)
          //   .call(g => g.select(".domain") // style axis and ticks
          //       .attr("stroke-opacity", 0.5))
          //   .call(g => g.selectAll(".tick line")
          //       .attr("stroke-opacity", 0.5))

          // draw logpile points
          let svg_add = this.svg_logpile
            .append("g")
            .classed(let_class, true)

          // TODO: change shape and appearance of volumes on chart
          // currently barcode
          svg_add
            .selectAll(".bar")
            .data(data, function(d) { return d.Type })
          .enter()
            .append("rect")
            .classed("bar", true)
            .attr("class", d => { return "bar " + d.Type }) // to grab in interaction
            .attr("x", d => xScale(x(d)))
            .attr("y", this.chart_height-y_height)
            .attr("width", 5)
            .attr("height", y_height)
            .attr("fill", "royalblue")
            .attr("stroke", "white")
            .on("mouseover", d => self.populateTooltip(d))					
            .on("mouseout", d => self.fadeEl(self.tooltip, 0, 50))

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
              // .style("width", "220px")
              // .style("height", "220px")
              // .style("left", (self.d3.event.pageX) + "px")		
              // .style("top", (self.d3.event.pageY) + "px");	

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

#logpile-container {
  height: 50vh;
  width: 90vw;
  margin: 5vw;
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