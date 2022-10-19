<template>
  <section>
    <div id="page-content">
      <h1><span class='pool pageText emph' >Pools</span> and <span class='flux pageText emph'>fluxes</span> in the water cycle</h1>
      <p>This chart shows the size of global <span class='pool pageText emph' >pools</span> and <span class='flux pageText emph'>fluxes</span> of water, and includes <span class='example pageText emph'>examples</span> of specific pools and fluxes for context. <span class='pool pageText emph' >Pools</span> are places where water is stored, like the ocean. <span class='flux pageText emph'>Fluxes</span> are the ways that water moves between pools, such as evaporation, precipitation, discharge, recharge, or human use. Learn more about the water cycle and see the water cycle diagram on the <a href="https://www.usgs.gov/water-cycle" target="_blank">USGS Water Science School website.</a></p>
      <br>
      <hr>
      <div id = "chart-title-container">
        <p>Showing <span class='pool pageText emph' >pool</span> and <span class='flux pageText emph' >flux</span> estimates,
          <span>        
            <button
              class="button"
              @click="toggleUncertainty"
              :text="currentUncertaintyStatus"
            >
              {{ currentUncertaintyStatus }}
            </button>
          </span>
          , on a 
          <span>
            <button
              class="button"
              @click="toggleScale"
              :text="scaleType"
            >
              {{ scaleType }}
            </button>
          </span>
          scale. 
          <span class = 'emph'>
            Click on any row of the chart to pull up more information
          </span>
        </p>
      </div>
      <dialogCard 
        :show="showDialog" 
        :title="cardTitle" 
        :type="cardType" 
        :color="cardColor" 
        :source="cardImageSource" 
        :sourceWebp="cardImageSourceWebp"
        :imageSite="cardImageSite"
        :sizePrefix = "cardSizePrefix"
        :size="cardFeatureSize" 
        :range="cardFeatureRange"
        :dataSource="cardFeatureDataSource" 
        :definitionPrefix="cardFeatureDefinitionPrefix"
        :definition="cardFeatureDefinition" 
        :close="close"
        :altText="altText"
      />
      <div id="chart-container" />
      <div id="caption-container">
        <p :text="axisExplanation"> Right now the x-axis is on a <span class='emph'> {{ scaleType }} </span> scale. {{ axisExplanation }}</p>
        <p>The data for this chart are adapted from <a href="https://www.nature.com/articles/s41561-019-0374-y" target="_blank">Abbott et al. (2019)</a>. Abbott et al. note that the <span class='emph'>estimate</span> for each pool or flux "represents the most recent or comprehensive individual estimate." The <span class='emph'>range</span> for each estimate, if shown, "represent[s] the range of reported values and their uncertainties."</p>
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
      scaleLog: true,
      scaleType: null,
      customNumberFormat: null,
      xScale: null,
      xAxisTop: null,
      domxAxisTop: null,
      xAxisBottom: null,
      domxAxisBottom: null,
      yAxis: null,
      tooltip: null,
      showDialog: false,
      cardTitle: null,
      cardSizePrefix: null,
      cardFeatureSize: null,
      cardFeatureRange:  null,
      cardFeatureDataSource: null,
      cardImageSource: null,
      cardImageSourceWebp: null,
      cardImageSite: null,
      cardFeatureDefinitionPrefix: null,
      cardFeatureDefinition: null,
      cardType: null,
      cardColor: null,
      altText: null,
      showUncertainty: false,
      currentUncertaintyStatus: null,
      axisExplanation: null
      }
  },
  mounted(){      
    this.d3 = Object.assign(d3Base);
    
    // Set starting value for uncertainty prompt
    this.currentUncertaintyStatus = "without ranges"

    // Set starting scale type
    this.scaleType = "log"

    // chart elements
    this.margin = this.mobileView ? { top: 50, right: 15, bottom: 20, left:  15 } : { top: 45, right: 15, bottom: 20, left: 300 }
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

    // create svg for chart
    this.svg = this.chartContainer.append("svg")
        .attr("class", 'chart')
        .attr("viewBox", "0 0 " + (this.chartWidth + this.margin.left + this.margin.right) + " " + (this.chartHeight + this.margin.top + this.margin.bottom))
        .attr("preserveAspectRatio", "xMidYMid meet")
        .attr("width", '100%')
        .attr("height", '100%')

    // append group to hold d3 chart
    this.svgChart = this.svg.append("g")
        .attr("transform","translate(" + this.margin.left + "," + this.margin.top + ")")
        .attr("id", "pool-flux-chart");

    this.loadData();
    },
    methods:{
        toggleUncertainty() {
          const self = this;

          // Update global value for show Uncertainty
          this.showUncertainty = !this.showUncertainty;
          
          // Toggle on or off uncertainty bars
          if (this.showUncertainty) {
            this.currentUncertaintyStatus = 'with ranges'
            this.d3.selectAll('.chartBandBkgd')
              .style("opacity", 1)
            this.d3.selectAll('.chartBand')
              .style("opacity", 0.3)
          } else {
            this.currentUncertaintyStatus = 'without ranges'
            this.d3.selectAll('.chartBandBkgd')
              .style("opacity", 0)
            this.d3.selectAll('.chartBand')
              .style("opacity", 0)
          }

          // Adjust y-axis label placement on mobile
          if (this.mobileView) {
            self.yAxis.selectAll("text")
              .transition()
              .duration(200)
              .attr("x", d => self.placeYAxisText(d, this.showUncertainty))
          }
        },
        toggleScale() {
          const self = this;

          // Update global value for whether or not scale is log
          this.scaleLog = !this.scaleLog;
          
          // Update scale type
          this.scaleType = this.scaleLog ? 'log' : 'linear' //this.d3.select('input[name="x-scale"]:checked').node().value;
          
          // set xScale to scale type
          this.xScale = this.scales[this.scaleType];

          // redraw X axis, with transition
          this.redraw();

          // update axis explanation
          this.setAxisExplanation();
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
          this.xScale = this.scales[this.scaleType];

          // set starting value for explanation of axis scale in figure caption
          this.setAxisExplanation();
          
          // draw chart
          this.drawChart(this.volume, 1)          
        },
        adaptScales(data, xMin) {
          Object.keys(this.scales).forEach(function (scaleType) {
            let dataMax = this.d3.max(data, d => d.range_high_km_3)
            if (this.mobileView) {
              let axisExtension = scaleType==='log' ? 1000000000000 : 300000000;
              this.scales[scaleType]
                .domain([xMin, dataMax  + axisExtension]) // extend axis
                .range([0, this.chartWidth]);
            } else {
              this.scales[scaleType]
                .domain([xMin, dataMax])
                .range([0, this.chartWidth]);
            }
          }, this);
        },
        drawChart(data, xMin) {

          const self = this;

          //// ADD AXES
          this.xAxisTop = this.d3.axisTop()
            .scale(self.xScale)
          this.xAxisBottom = this.d3.axisBottom()
            .scale(self.xScale)

          // Set x-axis number format, depending on scale type
          self.setXAxisNumberFormat(this.xAxisTop, this.scaleType, this.mobileView)
          self.setXAxisNumberFormat(this.xAxisBottom, this.scaleType, this.mobileView)

          this.domxAxisTop = this.svgChart.append("g")
            .attr("transform", "translate(0," + -3 + ")")
            .call(this.xAxisTop)
            .attr("class", "x_axis")
          this.domxAxisBottom = this.svgChart.append("g")
            .attr("transform", "translate(0," + this.chartHeight + ")")
            .call(this.xAxisBottom)
            .attr("class", "x_axis")

          // Add x-axis label on mobile and desktop
          this.svgChart.append("text")
               .attr("class", "x_label")
               .attr("text-anchor", "middle")
               .attr("x", this.chartWidth/2)
               .attr("y", -32)
               .text("Pool volume (km³) or flux rate (km³ per year)")

          // y axis scale for lollipop chart
          const yScale = this.d3.scaleBand()
            .range([0, this.chartHeight])
            .domain(data.map(d => d.feature_label))
            .padding(0);

          this.yAxis = this.svgChart.append("g")
            .call(this.d3.axisLeft(yScale))
            .attr("class", "y_axis")

          //// ADD CHART ELEMENTS
          // add lollipop lines
          let dataLines = this.svgChart.selectAll("chartLine")
            .data(data)
            .enter()
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' || d.type === 'example pool'  || d.type === 'example flux' })
            .append("line")
              .attr("x1",  d => self.xScale(d.value_km_3))
              .attr("x2", self.xScale(xMin))
              .attr("y1", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("y2", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("class", d => "chartLine " + d.type + " " + d.feature_class)
              .attr("id", d => d.feature_class)
              .style("stroke-dasharray", ("1, 3"))

          // Set default opacity for lollipop lines to 1 on mobile, 0 on desktop
          dataLines.style("opacity", d => this.mobileView ? 1 : 0)

          // add lines for uncertainty bands
          // background white band
          let dataBandBkgds = this.svgChart.selectAll("chartBandBkgd")
            .data(data)
            .enter()
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' })
            .append("line")
              .attr("x1",  d => self.xScale(d.range_high_km_3))
              .attr("x2", d => self.xScale(d.range_low_km_3))
              .attr("y1", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("y2", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("class", d => "chartBandBkgd " + d.type)
              .attr("id", d => d.feature_class)
              .style("stroke-linecap", "round")
              .style("opacity", 0)
          // colored partially transparent band
          let dataBands = this.svgChart.selectAll("chartBand")
            .data(data)
            .enter()
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' })
            .append("line")
              .attr("x1",  d => self.xScale(d.range_high_km_3))
              .attr("x2", d => self.xScale(d.range_low_km_3))
              .attr("y1", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("y2", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("class", d => "chartBand " + d.type)
              .attr("id", d => d.feature_class)
              .style("stroke-linecap", "round")
              .style("opacity", 0)

          // Add lollipop circles
          let dataPoints = this.svgChart.selectAll("chartCircle")
            .data(data)
            .enter()
            .filter(function(d) { return d.type === 'pool' || d.type === 'flux' || d.type === 'example pool'  || d.type === 'example flux' })
            .append("circle")
              .attr("cx", d => self.xScale(d.value_km_3))
              .attr("cy", d => yScale(d.feature_label) + yScale.bandwidth()/2)
              .attr("class", d => "chartCircle " + d.type)
              .attr("id", d => d.feature_class)

          // add lines to separate chart sections
          let lineBreak = this.svgChart.selectAll("breakLine")
            .data(data)
            .enter()
            .filter(function(d) { return d.feature_class === 'gap' && d.type != 'pool header'})
            .append("line")
              .attr("y1", d => yScale(d.feature_label))
              .attr("y2", d => yScale(d.feature_label))
              .attr("class", d => "breakLine " + d.type)
              .attr("id", d => d.feature_class)
              .style("stroke-linecap", "round")
              // .style("stroke-dasharray", "3,3")
              .style("opacity", 1)

          //// SET UP DIFFERENT STYLING OF CHART ELEMENTS ON DESKTOP AND MOBILE
          // Set different sizing for points and uncetainty bands on mobile and desktop
          let pointSize = this.mobileView ? 5 : 6
          dataPoints.attr("r", pointSize)
          dataBands.style("stroke-width", pointSize*2)
          dataBandBkgds.style("stroke-width", pointSize*2)
          let lineBreakX1 = this.mobileView ? 1 : -this.chartWidth/9
          let lineBreakX2 = this.mobileView ? this.chartWidth : this.chartWidth +10
          lineBreak.attr("x1", lineBreakX1)
          lineBreak.attr("x2", lineBreakX2)
          
          // Style y-axis text on mobile and desktop
          let textRectangleBuffer = 5
          let desktopTextAxisBuffer = pointSize + textRectangleBuffer
          let desktopRectangleAxisOffset = pointSize + textRectangleBuffer/2
          // assign class for interaction on desktop and styling on both
          this.yAxis.selectAll('text')
            .attr("class", d => "yAxisText " + self.getLabelData(d).type + ' ' + self.getLabelData(d).feature_class) //assign class for desktop interaction
          if (this.mobileView===true) {
            this.yAxis.selectAll('text')
              .attr("text-anchor","start")
              .attr("x", d => self.placeYAxisText(d, this.showUncertainty))
          } else {
            this.yAxis.selectAll('text')
              .attr("x", -desktopTextAxisBuffer)
          }
          
          //// SET UP INTERACTION
          // Append rectangles that overlay the chart that we can use to trigger interaction
          let svgInteractionGroup = this.svgChart.append("g")
            .attr("id", "interaction-container")

          let interactionRectangles = svgInteractionGroup.selectAll("interactionRectangle")
            .data(data)
            .enter()
            .append("rect")
              .attr("class", d => "interactionRectangle " + d.feature_class)
              .attr("y", d => yScale(d.feature_label))
              .attr("height", yScale.bandwidth())
              .style("fill", "white")
              .style("opacity", 0)
              .on("click", d => self.populateCard(d)) //trigger click on desktop and mobile

          // Set different x placement and width for interaction rectangles on mobile and desktop
          // on mobile - cover full width of chart + left and right margins
          // on desktop - start at y axis and cover width of chart + right margin
          let rectX = this.mobileView ? -this.margin.left : -desktopRectangleAxisOffset
          let rectWidth = this.mobileView ? this.chartWidth + this.margin.left + this.margin.right : desktopRectangleAxisOffset + this.chartWidth + this.margin.right
          interactionRectangles.attr("x", rectX)
          interactionRectangles.attr("width", rectWidth)

          // On desktop, add mouseover to interaction rectangles that overlay chart
          if (this.mobileView===false) {
            interactionRectangles
              .on("mouseover", function(d) {
                let current_feature = d.feature_class;
                if (current_feature != 'gap') {
                  self.mouseoverRect(current_feature)
                }
              })
              .on("mouseout", function(d) {
                let current_feature = d.feature_class;
                if (current_feature != 'gap') {
                  self.mouseoutRect(current_feature)
                }
              })
          }

          // On desktop, add additional interaction rectangles over y-axis text to trigger click and interaction
          if (this.mobileView===false) {
            let interactionRectanglesText = svgInteractionGroup.selectAll("interactionRectangleText")
              .data(data)
              .enter()
              .append("rect")
                .attr("class", d => "interactionRectangleText " + d.feature_class)
                .attr("x", -this.margin.left)
                .attr("y", d => yScale(d.feature_label))
                .attr("width", this.margin.left-desktopRectangleAxisOffset)
                .attr("height", yScale.bandwidth())
                .style("fill", "white")
                .style("opacity", 0)
                .on("click", d => self.populateCard(d))
                .on("mouseover", function(d) {
                  let current_feature = d.feature_class;
                  if (current_feature != 'gap') {
                  self.mouseoverRect(current_feature)
                }
                })
                .on("mouseout", function(d) {
                  let current_feature = d.feature_class;
                  if (current_feature != 'gap') {
                    self.mouseoutRect(current_feature)
                  }
                })
          }
          
          // Add element titles for screenreader (must be added at end of element creation)
          dataPoints.append('title').text(d => {
            let itemSizePrefix = d.type.includes('flux') ? "The rate estimate for " : "The volume estimate for ";
            let itemDefinitionPrefix = d.type.includes('example') ? '' : 'Definition: ';
            let itemTitle = d.feature_title + ". " + itemDefinitionPrefix + d.definition + " " + itemSizePrefix + (d.feature_title.charAt(0).toLowerCase() + d.feature_title.slice(1)) + " is " + d.value_km_3 + " " + d.units + ".";
            return itemTitle
          })
          dataBands.append('title').text(d => {
            let itemRangeDescription = d.type.includes('flux') ? "The range of the rate estimate for " : "The range of the volume estimate for ";
            let itemDefinitionPrefix = d.type.includes('example') ? '' : 'Definition: ';
            let itemTitle = d.feature_title + ". " + itemDefinitionPrefix + d.definition + " " + itemRangeDescription + (d.feature_title.charAt(0).toLowerCase() + d.feature_title.slice(1)) + " is " + d.range_low_km_3 + " to " + d.range_high_km_3 + " " + d.units + ".";
            return itemTitle
          })
        },
        mouseoverRect(current_feature) {
          const self = this;
          // dim y axis text for all but mouseovered row
          this.d3.selectAll('.yAxisText')
            .style("opacity", 0.5)
          this.d3.selectAll('.yAxisText.' + current_feature)
            .style("opacity", 1)
            .classed('pageText emph',true) // make bold and colored based on type
          // make interaction rectangles for all but mouseovered row slightly opaque to dim chart
          this.d3.selectAll('.interactionRectangle')
            .style("opacity", 0.5)
          this.d3.selectAll('.interactionRectangle.' + current_feature)
            .style("opacity", 0)
          this.d3.selectAll(".chartLine." + current_feature)
            .style("opacity", 1)
          this.d3.selectAll(".breakLine")
            .raise()
        },
        mouseoutRect(current_feature) {
          const self = this;
          // Make all y-axis text fully opaque
          this.d3.selectAll('.yAxisText')
            .style("opacity", 1)
            .classed('pageText emph',false)
          // Make chart interaction rectangles fully transparent
          this.d3.selectAll('.interactionRectangle')
            .style("opacity", 0)
          this.d3.selectAll(".chartLine." + current_feature)
            .style("opacity", 0)
        },
        imagePath(file){
          const image_src = 'https://labs.waterdata.usgs.gov/visualizations/images/' + file
          return image_src

        },
        populateCard(d){
          const self = this;

          if (d.type.includes('header') === false) {
            // use image_file from this.volume as ending to https://labs.waterdata.usgs.gov/visualizations/images/
            this.cardImageSource = self.imagePath(d.image_file)
            this.cardImageSourceWebp = self.imagePath(d.image_file + '?webp')
            //this.cardImageSourceWebp = self.imagePath(d.image_file.substring(0, d.image_file.indexOf('.')) + '.webp')
            this.cardImageSite = d.image_source

            // Populate card with information
            this.cardTitle = d.feature_title;
            this.cardType = d.type.charAt(0).toUpperCase() + d.type.slice(1);
            switch (d.type) {
              case 'pool':
                this.cardColor = '#9C6D07'; // 5:1 contrast (since text)
                break;
              case 'flux':
                this.cardColor = "#06846A"; // 5:1 contrast (since text)
                break;
              case 'example pool':
                this.cardColor = "#6E6E6E"; // 5:1 contrast (since text)
                break;
              case 'example flux':
                this.cardColor = "#6E6E6E"; // 5:1 contrast (since text)
                break;
            }

            // Provide volume/rate estimate
            this.cardSizePrefix = d.type.includes('flux') ? 'Rate estimate: ' : 'Volume estimate: '
            let unitsText = d.units==='cubic kilometers' ? 'km³' : 'km³ per year'
            this.cardFeatureSize = this.d3.format(',')(d.value_km_3) + ' ' +  unitsText
            
            // Provide range and data source, as applicable
            if (d.type === 'pool' || d.type === 'flux') {
              // Provide range
              this.cardFeatureRange = 'Range: ' + this.d3.format(',')(d.range_low_km_3) + ' - ' + this.d3.format(',')(d.range_high_km_3) + ' ' +  unitsText
              // Data source already provided in caption text
              this.cardFeatureDataSource = null
            } else {
              // No range to provide
              this.cardFeatureRange = ''
              // Provide data source
              this.cardFeatureDataSource = d.data_source
            }

            // Provide volume/rate estimate
            let definitionPrefix = d.type.includes('example') ? 'Description: ' : 'Definition: '
            this.cardFeatureDefinitionPrefix = definitionPrefix
            this.cardFeatureDefinition = d.definition
            this.showDialog = true;
            this.altText = d.alt_text;
          }
        },
        setAxisExplanation() {
          const logDescription = 'Using a log scale is useful when values are distributed across many orders of magnitude.';
          const logMovement = 'hen you move a fixed distance on a log axis, you multiply the starting value by a value of 10.'
          const linearDescription = 'A linear scale is like counting the days of the year, where each interval (day 1 to day 2) is equal to all the other intervals.' 
          const linearMovement = 'hen you move a fixed distance on a linear axis, you add a fixed value to the starting value.';
          this.axisExplanation = this.scaleType==='log' ? 
                  (logDescription + ' W' + logMovement + ' In contrast, w' + linearMovement + ' ' + linearDescription) : 
                  (linearDescription + ' W' + linearMovement + ' In contrast, w'  + logMovement + ' ' + logDescription);
        },
        setXAxisNumberFormat(currentXAxis, currentScale, currentlyMobile) {
          const self = this;

          if ((currentScale === 'log' ) && (currentlyMobile===false)) {
            currentXAxis
              .ticks(10)
              .tickFormat(d => this.xScale.tickFormat(0, self.d3.format(".1s"))(d).replace("G","B"))
          } else if ((currentScale === 'log' ) && (currentlyMobile===true)) {
            currentXAxis
              .ticks(10)
              .tickFormat(d => this.xScale.tickFormat(0, self.d3.format(".1s"))(d).replace("G","B"))
          } else if ((currentScale === 'linear') && (currentlyMobile===false)) {
            currentXAxis
              .ticks(10)
              .tickFormat(d =>this.customNumberFormat(d))
          }  else if (currentScale === 'linear' && currentlyMobile===true) {
            currentXAxis
              .ticks(6)
              .tickFormat(d =>this.customNumberFormat(d))
          }
        },
        getLabelData(currentFeature) {
          const self = this;
          // Pull data associated with y axis label
          let featureData = self.volume.filter(function(dataRow) {
            return dataRow.feature_label === currentFeature
          })[0]

          return (featureData)
        },
        placeYAxisText(currentFeature, currentlyShowingUncertainty) {
          const self = this;

          // Pull data associated with y axis label
          let featureData = self.getLabelData(currentFeature)

          // Identify feature type (pool/flux/example)
          let featureType = featureData.type

          // Set buffer distance between point and label
          let xBuffer = 10;

          // Set position of y axis label
          if (featureType.includes('header')) {
            return self.xScale(1)
          } else if (featureType === 'example pool' || featureType === 'example flux' || currentlyShowingUncertainty === false) {
            return self.xScale(featureData.value_km_3) + xBuffer
          } else if ((featureType === 'pool' || featureType === 'flux') && (currentlyShowingUncertainty === true)) {
            return self.xScale(featureData.range_high_km_3) + xBuffer
          }
          
        },
        redraw() {
          const self = this;
          
          const animationDuration = 2000;

          // Reset number format for x axes
          self.setXAxisNumberFormat(this.xAxisTop, this.scaleType, this.mobileView)
          self.setXAxisNumberFormat(this.xAxisBottom, this.scaleType, this.mobileView)

          // Shift chart elements
          this.domxAxisTop.transition()
              .duration(animationDuration)
              .call(self.xAxisTop.scale(this.xScale));
          this.domxAxisBottom.transition()
              .duration(animationDuration)
              .call(self.xAxisBottom.scale(this.xScale));
          this.svgChart.selectAll(".chartBand")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.range_high_km_3))
            .attr("x2", d => self.xScale(d.range_low_km_3))
          this.svgChart.selectAll(".chartBandBkgd")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.range_high_km_3))
            .attr("x2", d => self.xScale(d.range_low_km_3))
          this.svgChart.selectAll(".chartCircle")
            .transition()
            .duration(animationDuration)
            .attr("cx", d => self.xScale(d.value_km_3))
          this.svgChart.selectAll(".chartLine")
            .transition()
            .duration(animationDuration)
            .attr("x1", d => self.xScale(d.value_km_3))
          
          // If on mobile, shift y axis labels
          if (this.mobileView) {
            self.yAxis.selectAll("text")
              .transition()
              .duration(animationDuration)
              .attr("x", d => self.placeYAxisText(d, this.showUncertainty))
          }
    },
    }
}
</script>
<style scoped lang="scss">
  $poolColor: #bf8508; //3.2:1 contrast
  $fluxColor: #0aa687; //3:1 contrast
  $poolColorDark: #9C6D07; //4.5:1 contrast
  $fluxColorDark: #06846A; //4.5:1 contrast
  $lightestGrey: #949494; //3:1 contrast
  $neutralGrey: #919191; //3.15:1 contrast
  $darkGrey: #6E6E6E; //5:1 contrast
  #page-content {
    display: block;
    max-width: 1500px;
    margin: 0 auto;
  }
  #chart-container {
    min-height: 400px;
    height: 75vh;
    width: 90vw;
    max-width: 1500px;
    margin-top: 1vh;
    margin-bottom: 1vh;
    @media screen and (max-height: 770px) {
        height: 120vh;
    }
    @media screen and (max-width: 600px) {
        height: 100vh;
    }
  }
  #caption-container {
    display: block;
  }
  .pool.pageText {
    color: $poolColorDark;
  }
  .flux.pageText {
    color: $fluxColorDark;
  }
  .example.pageText {
    color: $darkGrey;
  }
  .button {
    --tw-bg-opacity: 1;
    background-color: white;
    border: 0.5px solid #A9A9A9;
    border-radius: 0.25rem;
    margin-left: auto;
    margin-right: 2px;
    margin-top: 0.5rem;
    padding: 5px 8px 5px 8px;
    max-width: 24rem;
    box-shadow:
      1px 2px 2px hsl(0deg, 0%, 40% / 0.47);
    @media screen and (max-width: 600px) {
      margin-top: 0rem;
      margin-bottom: 0.1rem;
    }
  }
  .button:hover {
    background-color: $darkGrey;
    color: white;
    box-shadow:
      3px 6px 6px hsl(0deg, 0%, 35% / 0.41);
    @media screen and (max-width: 600px) {
      background-color: white;
      color: black;
      box-shadow:
      1px 2px 2px hsl(0deg, 0%, 35% / 0.47);
    }
  }
</style>
<style lang="scss">
  // Fonts
  @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@200;300;400;600;700;900&display=swap');
  @import url('https://fonts.googleapis.com/css2?family=Assistant:wght@200;300;400;500;600;700;800&display=swap');
  $Cairo: 'Cairo', sans-serif;
  $Assistant: 'Assistant', sans-serif;

  $poolColor: #bf8508; //3.2:1 contrast
  $fluxColor: #0aa687; //3:1 contrast
  $poolColorDark: #9C6D07; //4.5:1 contrast
  $fluxColorDark: #06846A; //4.5:1 contrast
  $lightestGrey: #949494; //3:1 contrast
  $neutralGrey: #919191; //3.15:1 contrast
  $darkGrey: #6E6E6E; //5:1 contrast


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
  }
  .header{
    font-weight: 700;
  }
  .pool.pageText {
    color: $poolColorDark;
    fill: $poolColorDark;
  }
  .flux.pageText {
    color: $fluxColorDark;
    fill: $fluxColorDark;
  }
  .example.pageText {
    color: $darkGrey;
    fill: $darkGrey;
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
  .breakLine {
    stroke: $neutralGrey;
    stroke-width: 0.25px;
  }
  .y_axis line {
    visibility:hidden;
  }
  .y_axis path {
    visibility:hidden;
  }
  .yAxisText {
    stroke: None;
    fill: #000000;
    font-size: 1.6em;
    padding: 1em 0 0 0; 
    font-family: $Assistant;
    @media screen and (max-height: 770px) {
        font-size: 1.25em;
    }
    @media screen and (max-width: 600px) {
        font-size: 1.1em;
    }
  }
  .yAxisText.pool.header {
    fill: $poolColorDark;
  }
  .yAxisText.flux.header {
    fill: $fluxColorDark;
  }
  .yAxisText.example {
    stroke: None;
    fill: $darkGrey;
    font-style: italic;
  }
  .x_axis text {
    font-size: 1.4em;
    padding: 1em 0 0 0; 
    font-family: $Assistant;
    @media screen and (max-height: 770px) {
        font-size: 1.2em;
    }
    @media screen and (max-width: 600px) {
        font-size: 1.1em;
    }
  }
  #x-label-container {
    text-align: center;
    height: 1.3em;
    line-height: 1em;
    @media screen and (max-width: 600px) {
        height: 1em;
        line-height: 1em;
    }
  }
  .x_label {
    font-size: 1em;
    padding: 0em 0 0 0;
    font-family: $Assistant;
    @media screen and (max-width: 600px) {
        font-size: 0.8em;
    }
  }
</style>