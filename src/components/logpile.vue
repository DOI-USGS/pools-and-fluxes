<template>
  <section>
    <div id="logpile-container" />
    <div class="chart-container js-chart-container">
    <form class="controls">
        Scale:
        <label><input type="radio" name="x-scale" value="linear">Linear</label> 
        <label><input type="radio" name="x-scale" value="log10">Log10</label>
    </form>
    <svg class="chart js-chart"></svg>
</div>
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
      svg_chart: null,
      logpile_container: null,
      scales: {
        linear: d3.scaleLinear(),
        log10:  d3.scaleLog().base(10)
    },

    }
  },
  mounted(){      
      this.d3 = Object.assign(d3Base);

    // chart elements
    this.logpile_container = this.d3.select("#logpile-container")
    this.w = document.getElementById("logpile-container").offsetWidth;
    this.h = document.getElementById("logpile-container").offsetHeight;
    
    // create svg that will hold chart
    this.svg_logpile = this.d3.select("#logpile-container")
      .append("svg")
      .classed("logpile-chart", true)
      .attr("viewBox", "0 0 " + this.w + " " + this.h)
      .attr("preserveAspectRatio", "xMidYMid meet")

    this.loadData();

    // resize chart when window changes 
    //window.addEventListener("resize", this.drawChart)

    },
    methods:{
        loadData(){
            const self = this;

            // read in data
            let promises = [
                self.d3.csv("https://labs.waterdata.usgs.gov/visualizations/data/abbott_pools_and_fluxes.csv", this.d3.autoType),
            ];
            Promise.all(promises).then(self.callback);
        },
        callback(data){
          const self = this;

          // pools and fluxes of water
          this.volume = data[0];
          //console.log(this.volume)

          this.addlogpile(this.volume)
        },
        addlogpile(data){
          // draw logpile 
          this.drawChart(data, {
            x: d => d.Vol_km3,
            type: this.d3.scaleLog,
            y_pos: 100,
            x_min: 1, // necessary for log
            var_class: 'pool'
          })
        },
        resize(){
            // make chart responsive
        },
        drawChart(data, {
          value = d => d, // convenience alias for x
          x = value, // given d in data, returns value
          type = this.d3.scaleLinear,
          x_min,
          y_pos,
          y_height = 50,
          var_class
        } = {}) {

          const x_margin = 20;

          // x axis scale
          var xScale = type()
            .domain([x_min, this.d3.max(data, x)])
            .range([30, this.w-30])

          var xAxis = this.d3.axisBottom(xScale)

          // add pools and fluxes
          this.svg_logpile.append("g")
            .attr("transform", "translate(" + 0 + ", " + y_pos + ")")
            .attr("class", "x-axis")
            .call(xAxis)
            .call(g => g.select(".domain")
                .attr("stroke-opacity", 0.5))
            .call(g => g.selectAll(".tick line")
                .attr("stroke-opacity", 0.5))

          // draw logpile points
          var svg_add = this.svg_logpile
            .append("g")
            .classed(var_class, true)

          svg_add
            .selectAll(".bar")
            .data(data, function(d) { return d.Type })
            .enter()
            .append("rect")
            .classed("bar", true)
            .attr("class", d => { return "bar " + d.Type }) // to grab in interaction
            .attr("x", d => xScale(x(d)))
            .attr("y", y_height)
            .attr("width", 2)
            .attr("height", y_height)
            .attr("opacity", 0.85)
            .attr("fill", "pink")    

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

</style>