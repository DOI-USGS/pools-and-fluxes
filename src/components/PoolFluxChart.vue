<template>
  <section>
    <div
      id="page-content"
      role="main"
    >
      <header
        aria-level="1"
        aria-label="page title"
      >
        <h1 role="none presentation">
          <span class="pool pageText emph">Pools</span> and <span class="flux pageText emph">fluxes</span> in the water cycle
        </h1>
      </header>
      <section aria-label="page description">
        <p>
          This chart shows the size of global <span class="pool pageText emph">pools</span> and <span class="flux pageText emph">fluxes</span> of water, and includes <span class="example pageText emph">examples</span> of specific pools and fluxes for context. <span class="pool pageText emph">Pools</span> are places where water is stored, like the ocean. <span class="flux pageText emph">Fluxes</span> are the ways that water moves between pools, such as evaporation, precipitation, discharge, recharge, or human use. 
        </p>
        <br>
      </section>
      <hr
        class="section-divider"
        role="none presentation"
      >
      <section>      
        <div
          id="chart-title-container"
          aria-level="2"
        >
          <p>
            <span aria-hidden="true">Showing <span class="pool pageText emph">pool</span> and <span class="flux pageText emph">flux</span> estimates,
              <span>        
                <button
                  aria-pressed="!scaleLog"
                  class="button"
                  :text="currentUncertaintyStatus"
                  @click="toggleUncertainty"
                >
                  {{ currentUncertaintyStatus }}
                </button>
              </span>
              , on a 
              <span>
                <button
                  aria-pressed="showUncertainty"
                  class="button"
                  :text="scaleType"
                  @click="toggleScale"
                >
                  {{ scaleType }}
                </button>
              </span>
              scale.</span> 
            <span class="emph">
              Click on any row of the chart to pull up more information
            </span>
          </p>
        </div>
      </section>
      <DialogCard
        :aria-hidden="!showDialog"
        :show="showDialog" 
        :title="cardTitle" 
        :type="cardType" 
        :color="cardColor" 
        :source="cardImageSource" 
        :image-site="cardImageSite"
        :size-prefix="cardSizePrefix"
        :size="cardFeatureSize" 
        :range="cardFeatureRange"
        :data-source="cardFeatureDataSource" 
        :definition-prefix="cardFeatureDefinitionPrefix"
        :definition="cardFeatureDefinition" 
        :close="close"
        :alt-text="altText"
      />
      <figure id="chart-figure">
        <div
          id="chart-container"
          aria-label="interactive chart"
        />
        <figcaption
          id="caption-container"
          aria-label="chart caption"
        >
          <section aria-hidden="true">
            <p :text="axisExplanation">
              Right now the x-axis is on a <span class="emph"> {{ scaleType }} </span> scale. {{ axisExplanation }}
            </p>
          </section>
          <section aria-label="data citation">
            <p>
              The data for this chart are adapted from <a
                role="link"
                href="https://www.nature.com/articles/s41561-019-0374-y"
                target="_blank"
              >Abbott et al. (2019)</a>. Abbott et al. note that the <span class="emph">estimate</span> for each pool or flux "represents the most recent or comprehensive individual estimate." The <span class="emph">range</span> for each estimate, if shown, "represent[s] the range of reported values and their uncertainties."
            </p>
          </section>
        </figcaption>
      </figure>
      <RelatedResources :in-english="true" />
      <br>
      <hr class="section-divider">
      <Authorship :authors="authors" />
    </div>
  </section>
</template>
<script setup>
import { defineAsyncComponent, onMounted, ref } from 'vue';
import * as d3Base from 'd3';
import { isMobile } from 'mobile-device-detect';
import authors from '@/assets/text/authors';
import RelatedResources from '@/components/RelatedResources.vue'; 

defineOptions({ name: 'PoolFluxChart' });

const DialogCard = defineAsyncComponent(() => import('@/components/DialogBox.vue'));
const Authorship = defineAsyncComponent(() => import('@/components/AuthorshipSection.vue'));

const publicPath = import.meta.env.BASE_URL;
    const d3 = ref(null);
    const mobileView = isMobile;

    let volume = [];
    let w = null;
    let h = null;
    let margin = null;
    let chartWidth = null;
    let chartHeight = null;
    let svg = null;
    let svgChart = null;
    let chartContainer = null;
    let scales = null;
    let customNumberFormat = null;
    let xScale = null;
    let xAxisTop = null;
    let domxAxisTop = null;
    let xAxisBottom = null;
    let domxAxisBottom = null;
    let yAxis = null;

    const scaleLog = ref(true);
    const scaleType = ref(null);
    const showDialog = ref(false);
    const cardTitle = ref(null);
    const cardSizePrefix = ref(null);
    const cardFeatureSize = ref(null);
    const cardFeatureRange = ref(null);
    const cardFeatureDataSource = ref(null);
    const cardImageSource = ref(null);
    const cardImageSite = ref(null);
    const cardFeatureDefinitionPrefix = ref(null);
    const cardFeatureDefinition = ref(null);
    const cardType = ref(null);
    const cardColor = ref(null);
    const altText = ref(null);
    const showUncertainty = ref(false);
    const currentUncertaintyStatus = ref(null);
    const axisExplanation = ref(null);

    function toggleUncertainty() {
      showUncertainty.value = !showUncertainty.value;

      if (showUncertainty.value) {
        currentUncertaintyStatus.value = 'with ranges';
        d3.value.selectAll('.chartBandBkgd').style('visibility', 'visible');
        d3.value.selectAll('.chartBand').style('visibility', 'visible');
      } else {
        currentUncertaintyStatus.value = 'without ranges';
        d3.value.selectAll('.chartBandBkgd').style('visibility', 'hidden');
        d3.value.selectAll('.chartBand').style('visibility', 'hidden');
      }

      if (mobileView && yAxis) {
        yAxis
          .selectAll('text')
          .transition()
          .duration(200)
          .attr('x', (feature) => placeYAxisText(feature, showUncertainty.value));
      }
    }

    function toggleScale() {
      scaleLog.value = !scaleLog.value;
      scaleType.value = scaleLog.value ? 'log' : 'linear';
      xScale = scales[scaleType.value];
      redraw();
      setAxisExplanation();
    }

    function close() {
      showDialog.value = false;
    }

    function loadData() {
      const promises = [
        d3.value.csv(`${publicPath}data/pools-fluxes-examples-limited.csv`, d3.value.autoType)
      ];
      Promise.all(promises).then(callback);
    }

    function callback(data) {
      volume = data[0];

      const formatBillion = (x) => `${d3.value.format('.1f')(x / 1e9)}B`;
      const formatMillion = (x) => `${d3.value.format('.0f')(x / 1e6)}M`;
      const formatThousand = (x) => `${d3.value.format('.0f')(x / 1e3)}k`;

      customNumberFormat = (x) => {
        const v = Math.abs(x);
        return (v >= 0.9995e9 ? formatBillion : v >= 0.9995e6 ? formatMillion : formatThousand)(x);
      };

      adaptScales(volume, 1);
      xScale = scales[scaleType.value];
      setAxisExplanation();
      drawChart(volume, 1);
    }

    function adaptScales(data, xMin) {
      Object.keys(scales).forEach((currentScaleType) => {
        const dataMax = d3.value.max(data, (datum) => datum.range_high_km_3);
        if (mobileView) {
          const axisExtension = currentScaleType === 'log' ? 1000000000000 : 300000000;
          scales[currentScaleType]
            .domain([xMin, dataMax + axisExtension])
            .range([0, chartWidth]);
        } else {
          scales[currentScaleType].domain([xMin, dataMax]).range([0, chartWidth]);
        }
      });
    }

    function drawChart(data, xMin) {
      svgChart
        .append('text')
        .attr('class', 'x_label')
        .attr('text-anchor', 'middle')
        .attr('x', chartWidth / 2)
        .attr('y', -32)
        .attr('aria-hidden', 'true')
        .text('Pool volume (km³) or flux rate (km³ per year)')
        .append('title')
        .text('X axis label: Pool volume (km³) or flux rate (km³ per year)');

      xAxisTop = d3.value.axisTop().scale(xScale);
      xAxisBottom = d3.value.axisBottom().scale(xScale);

      setXAxisNumberFormat(xAxisTop, scaleType.value, mobileView);
      setXAxisNumberFormat(xAxisBottom, scaleType.value, mobileView);

      domxAxisTop = svgChart
        .append('g')
        .attr('transform', 'translate(0,-3)')
        .call(xAxisTop)
        .attr('class', 'x_axis');
      domxAxisBottom = svgChart
        .append('g')
        .attr('transform', `translate(0,${chartHeight})`)
        .call(xAxisBottom)
        .attr('class', 'x_axis');

      domxAxisTop.selectAll('text').attr('aria-hidden', 'true');
      domxAxisBottom.selectAll('text').attr('aria-hidden', 'true');

      const yScale = d3.value
        .scaleBand()
        .range([0, chartHeight])
        .domain(data.map((datum) => datum.feature_label))
        .padding(0);

      yAxis = svgChart.append('g').call(d3.value.axisLeft(yScale)).attr('class', 'y_axis');

      const dataLines = svgChart
        .selectAll('chartLine')
        .data(data)
        .enter()
        .filter(
          (datum) =>
            datum.type === 'pool' ||
            datum.type === 'flux' ||
            datum.type === 'example pool' ||
            datum.type === 'example flux'
        )
        .append('line')
        .attr('x1', (datum) => xScale(datum.value_km_3))
        .attr('x2', xScale(xMin))
        .attr('y1', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('y2', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('class', (datum) => `chartLine ${datum.type} ${datum.feature_class}`)
        .attr('id', (datum) => datum.feature_class)
        .style('stroke-dasharray', '1, 3');

      dataLines.style('opacity', () => (mobileView ? 1 : 0));

      const dataBandBkgds = svgChart
        .selectAll('chartBandBkgd')
        .data(data)
        .enter()
        .filter((datum) => datum.type === 'pool' || datum.type === 'flux')
        .append('line')
        .attr('x1', (datum) => xScale(datum.range_high_km_3))
        .attr('x2', (datum) => xScale(datum.range_low_km_3))
        .attr('y1', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('y2', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('class', (datum) => `chartBandBkgd ${datum.type}`)
        .attr('id', (datum) => datum.feature_class)
        .style('stroke-linecap', 'round')
        .style('visibility', 'hidden');

      const dataBands = svgChart
        .selectAll('chartBand')
        .data(data)
        .enter()
        .filter((datum) => datum.type === 'pool' || datum.type === 'flux')
        .append('line')
        .attr('x1', (datum) => xScale(datum.range_high_km_3))
        .attr('x2', (datum) => xScale(datum.range_low_km_3))
        .attr('y1', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('y2', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('class', (datum) => `chartBand ${datum.type}`)
        .attr('id', (datum) => datum.feature_class)
        .style('stroke-linecap', 'round')
        .style('opacity', 0.3)
        .style('visibility', 'hidden');

      const dataPoints = svgChart
        .selectAll('chartCircle')
        .data(data)
        .enter()
        .filter(
          (datum) =>
            datum.type === 'pool' ||
            datum.type === 'flux' ||
            datum.type === 'example pool' ||
            datum.type === 'example flux'
        )
        .append('circle')
        .attr('cx', (datum) => xScale(datum.value_km_3))
        .attr('cy', (datum) => yScale(datum.feature_label) + yScale.bandwidth() / 2)
        .attr('class', (datum) => `chartCircle ${datum.type}`)
        .attr('id', (datum) => datum.feature_class);

      const lineBreak = svgChart
        .selectAll('breakLine')
        .data(data)
        .enter()
        .filter((datum) => datum.feature_class === 'gap' && datum.type !== 'pool header')
        .append('line')
        .attr('y1', (datum) => yScale(datum.feature_label))
        .attr('y2', (datum) => yScale(datum.feature_label))
        .attr('class', (datum) => `breakLine ${datum.type}`)
        .attr('id', (datum) => datum.feature_class)
        .style('stroke-linecap', 'round')
        .style('opacity', 1);

      const pointSize = mobileView ? 5 : 6;
      dataPoints.attr('r', pointSize);
      dataBands.style('stroke-width', pointSize * 2);
      dataBandBkgds.style('stroke-width', pointSize * 2);
      const lineBreakX1 = mobileView ? 1 : -chartWidth / 9;
      const lineBreakX2 = mobileView ? chartWidth : chartWidth + 10;
      lineBreak.attr('x1', lineBreakX1);
      lineBreak.attr('x2', lineBreakX2);

      const textRectangleBuffer = 5;
      const desktopTextAxisBuffer = pointSize + textRectangleBuffer;
      const desktopRectangleAxisOffset = pointSize + textRectangleBuffer / 2;

      yAxis
        .selectAll('text')
        .attr(
          'class',
          (feature) => `yAxisText ${getLabelData(feature).type} ${getLabelData(feature).feature_class}`
        )
        .attr('aria-hidden', 'true');

      if (mobileView === true) {
        yAxis
          .selectAll('text')
          .attr('text-anchor', 'start')
          .attr('x', (feature) => placeYAxisText(feature, showUncertainty.value));
      } else {
        yAxis.selectAll('text').attr('x', -desktopTextAxisBuffer);
      }

      const svgInteractionGroup = svgChart.append('g').attr('id', 'interaction-container');

      const interactionRectangles = svgInteractionGroup
        .selectAll('interactionRectangle')
        .data(data)
        .enter()
        .filter(
          (datum) =>
            datum.type === 'pool' ||
            datum.type === 'flux' ||
            datum.type === 'example pool' ||
            datum.type === 'example flux'
        )
        .append('rect')
        .attr('class', (datum) => `interactionRectangle ${datum.feature_class}`)
        .attr('y', (datum) => yScale(datum.feature_label))
        .attr('height', yScale.bandwidth())
        .attr('tabindex', '0')
        .attr('role', 'button')
        .style('fill', 'white')
        .style('opacity', 0)
        .on('click', (_event, datum) => populateCard(datum));

      interactionRectangles.each(function () {
        this.addEventListener('keypress', function (event) {
          if (event.key === 'Enter' || event.keyCode === 13) {
            const itemFeatureClass = this.classList[1];
            const featureData = volume.filter((dataRow) => dataRow.feature_class === itemFeatureClass)[0];
            populateCard(featureData);
          }
        });
      });

      const rectX = mobileView ? -margin.left : -desktopRectangleAxisOffset;
      const rectWidth = mobileView
        ? chartWidth + margin.left + margin.right
        : desktopRectangleAxisOffset + chartWidth + margin.right;
      interactionRectangles.attr('x', rectX);
      interactionRectangles.attr('width', rectWidth);

      if (mobileView === false) {
        interactionRectangles
          .on('mouseover', (_event, datum) => mouseoverRect(datum.feature_class))
          .on('mouseout', (_event, datum) => mouseoutRect(datum.feature_class));
      }

      interactionRectangles.append('title').text((datum) => {
        const featureName = datum.type.includes('example')
          ? datum.feature_title
          : datum.feature_title.charAt(0).toLowerCase() + datum.feature_title.slice(1);
        return `Click to learn more about ${featureName}.`;
      });

      if (mobileView === false) {
        svgInteractionGroup
          .selectAll('interactionRectangleText')
          .data(data)
          .enter()
          .filter(
            (datum) =>
              datum.type === 'pool' ||
              datum.type === 'flux' ||
              datum.type === 'example pool' ||
              datum.type === 'example flux'
          )
          .append('rect')
          .attr('class', (datum) => `interactionRectangleText ${datum.feature_class}`)
          .attr('x', -margin.left)
          .attr('y', (datum) => yScale(datum.feature_label))
          .attr('width', margin.left - desktopRectangleAxisOffset)
          .attr('height', yScale.bandwidth())
          .attr('aria-hidden', 'true')
          .style('fill', 'white')
          .style('opacity', 0)
          .on('click', (_event, datum) => populateCard(datum))
          .on('mouseover', (_event, datum) => mouseoverRect(datum.feature_class))
          .on('mouseout', (_event, datum) => mouseoutRect(datum.feature_class));
      }

      dataPoints.append('title').text((datum) => {
        const itemName = datum.type.includes('example')
          ? datum.feature_title
          : datum.feature_title.charAt(0).toLowerCase() + datum.feature_title.slice(1);
        const itemSizePrefix = datum.type.includes('flux')
          ? 'The rate estimate for '
          : 'The volume estimate for ';
        return `${datum.feature_title}. ${datum.type.charAt(0).toUpperCase() + datum.type.slice(1)}. ${itemSizePrefix}${itemName} is ${d3.value.format(',')(datum.value_km_3)} ${datum.units}.`;
      });

      dataBands.append('title').text((datum) => {
        const itemName = datum.type.includes('example')
          ? datum.feature_title
          : datum.feature_title.charAt(0).toLowerCase() + datum.feature_title.slice(1);
        const itemRangeDescription = datum.type.includes('flux')
          ? 'The range of the rate estimate for '
          : 'The range of the volume estimate for ';
        return `${datum.feature_title}. ${datum.type}. ${itemRangeDescription}${itemName} is ${d3.value.format(',')(datum.range_low_km_3)} to ${d3.value.format(',')(datum.range_high_km_3)} ${datum.units}.`;
      });
    }

    function mouseoverRect(currentFeature) {
      d3.value.selectAll('.yAxisText').style('opacity', 0.5);
      d3.value
        .selectAll(`.yAxisText.${currentFeature}`)
        .style('opacity', 1)
        .classed('pageText emph', true);
      d3.value.selectAll('.interactionRectangle').style('opacity', 0.5);
      d3.value.selectAll(`.interactionRectangle.${currentFeature}`).style('opacity', 0);
      d3.value.selectAll(`.chartLine.${currentFeature}`).style('opacity', 1);
      d3.value.selectAll('.breakLine').raise();
    }

    function mouseoutRect(currentFeature) {
      d3.value.selectAll('.yAxisText').style('opacity', 1).classed('pageText emph', false);
      d3.value.selectAll('.interactionRectangle').style('opacity', 0);
      d3.value.selectAll(`.chartLine.${currentFeature}`).style('opacity', 0);
    }

    function imagePath(file) {
      const basePath = import.meta.env.VITE_APP_S3_PROD_URL || '';
      const normalizedBasePath = basePath.replace(/\/+$/, '');
      const normalizedFile = String(file || '').replace(/^\/+/, '');
      return `${normalizedBasePath}/images/${normalizedFile}`;
    }

    function populateCard(datum) {
      cardImageSource.value = imagePath(datum.image_file);
      cardImageSite.value = datum.image_source;
      altText.value = datum.alt_text;

      cardTitle.value = datum.feature_title;
      cardType.value = datum.type.charAt(0).toUpperCase() + datum.type.slice(1);
      switch (datum.type) {
        case 'pool':
          cardColor.value = '#9C6D07';
          break;
        case 'flux':
          cardColor.value = '#06846A';
          break;
        case 'example pool':
        case 'example flux':
          cardColor.value = '#6E6E6E';
          break;
      }

      cardSizePrefix.value = datum.type.includes('flux') ? 'Rate estimate: ' : 'Volume estimate: ';
      const unitsText = datum.units === 'cubic kilometers' ? 'km³' : 'km³ per year';
      cardFeatureSize.value = `${d3.value.format(',')(datum.value_km_3)} ${unitsText}`;

      if (datum.type === 'pool' || datum.type === 'flux') {
        cardFeatureRange.value = `Range: ${d3.value.format(',')(datum.range_low_km_3)} - ${d3.value.format(',')(datum.range_high_km_3)} ${unitsText}`;
        cardFeatureDataSource.value = null;
      } else {
        cardFeatureRange.value = '';
        cardFeatureDataSource.value = datum.data_source;
      }

      cardFeatureDefinitionPrefix.value = datum.type.includes('example')
        ? 'Description: '
        : 'Definition: ';
      cardFeatureDefinition.value = datum.definition;
      showDialog.value = true;
    }

    function setAxisExplanation() {
      const logDescription =
        'Using a log scale is useful when values are distributed across many orders of magnitude.';
      const logMovement =
        'hen you move a fixed distance on a log axis, you multiply the starting value by a value of 10.';
      const linearDescription =
        'A linear scale is like counting the days of the year, where each interval (day 1 to day 2) is equal to all the other intervals.';
      const linearMovement =
        'hen you move a fixed distance on a linear axis, you add a fixed value to the starting value.';
      axisExplanation.value =
        scaleType.value === 'log'
          ? `${logDescription} W${logMovement} In contrast, w${linearMovement} ${linearDescription}`
          : `${linearDescription} W${linearMovement} In contrast, w${logMovement} ${logDescription}`;
    }

    function setXAxisNumberFormat(currentXAxis, currentScale, currentlyMobile) {
      if (currentScale === 'log' && currentlyMobile === false) {
        currentXAxis
          .ticks(10)
          .tickFormat((datum) => xScale.tickFormat(0, d3.value.format('.1s'))(datum).replace('G', 'B'));
      } else if (currentScale === 'log' && currentlyMobile === true) {
        currentXAxis
          .ticks(10)
          .tickFormat((datum) => xScale.tickFormat(0, d3.value.format('.1s'))(datum).replace('G', 'B'));
      } else if (currentScale === 'linear' && currentlyMobile === false) {
        currentXAxis.ticks(10).tickFormat((datum) => customNumberFormat(datum));
      } else if (currentScale === 'linear' && currentlyMobile === true) {
        currentXAxis.ticks(6).tickFormat((datum) => customNumberFormat(datum));
      }
    }

    function getLabelData(currentFeature) {
      return volume.filter((dataRow) => dataRow.feature_label === currentFeature)[0];
    }

    function placeYAxisText(currentFeature, currentlyShowingUncertainty) {
      const featureData = getLabelData(currentFeature);
      const featureType = featureData.type;
      const xBuffer = 10;

      if (featureType.includes('header')) {
        return xScale(1);
      }
      if (
        featureType === 'example pool' ||
        featureType === 'example flux' ||
        currentlyShowingUncertainty === false
      ) {
        return xScale(featureData.value_km_3) + xBuffer;
      }
      if (
        (featureType === 'pool' || featureType === 'flux') &&
        currentlyShowingUncertainty === true
      ) {
        return xScale(featureData.range_high_km_3) + xBuffer;
      }
      return xScale(featureData.value_km_3) + xBuffer;
    }

    function redraw() {
      const animationDuration = 2000;

      setXAxisNumberFormat(xAxisTop, scaleType.value, mobileView);
      setXAxisNumberFormat(xAxisBottom, scaleType.value, mobileView);

      domxAxisTop.transition().duration(animationDuration).call(xAxisTop.scale(xScale));
      domxAxisBottom.transition().duration(animationDuration).call(xAxisBottom.scale(xScale));
      svgChart
        .selectAll('.chartBand')
        .transition()
        .duration(animationDuration)
        .attr('x1', (datum) => xScale(datum.range_high_km_3))
        .attr('x2', (datum) => xScale(datum.range_low_km_3));
      svgChart
        .selectAll('.chartBandBkgd')
        .transition()
        .duration(animationDuration)
        .attr('x1', (datum) => xScale(datum.range_high_km_3))
        .attr('x2', (datum) => xScale(datum.range_low_km_3));
      svgChart
        .selectAll('.chartCircle')
        .transition()
        .duration(animationDuration)
        .attr('cx', (datum) => xScale(datum.value_km_3));
      svgChart
        .selectAll('.chartLine')
        .transition()
        .duration(animationDuration)
        .attr('x1', (datum) => xScale(datum.value_km_3));

      if (mobileView) {
        yAxis
          .selectAll('text')
          .transition()
          .duration(animationDuration)
          .attr('x', (feature) => placeYAxisText(feature, showUncertainty.value));
      }
    }

onMounted(() => {
  d3.value = Object.assign(d3Base);
  currentUncertaintyStatus.value = 'without ranges';
  scaleType.value = 'log';

  margin = mobileView
    ? { top: 50, right: 15, bottom: 20, left: 15 }
    : { top: 45, right: 15, bottom: 20, left: 300 };

  const chartContainerElement = document.getElementById('chart-container');
  if (!chartContainerElement) {
    return;
  }

  w = chartContainerElement.offsetWidth;
  h = chartContainerElement.offsetHeight;
  chartWidth = w - margin.left - margin.right;
  chartHeight = h - margin.top - margin.bottom;
  chartContainer = d3.value.select('#chart-container');

  scales = {
    log: d3.value.scaleLog().base(10),
    linear: d3.value.scaleLinear()
  };

  svg = chartContainer
    .append('svg')
    .attr('class', 'chart')
    .attr(
      'viewBox',
      `0 0 ${chartWidth + margin.left + margin.right} ${chartHeight + margin.top + margin.bottom}`
    )
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('width', '100%')
    .attr('height', '100%');

  svgChart = svg
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`)
    .attr('id', 'pool-flux-chart');

  loadData();
});
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
    --content-width: 95%;
  }
  #page-content > header,
  #page-content > section[aria-label="page description"],
  #chart-title-container,
  #chart-figure {
    width: var(--content-width);
    margin-left: auto;
    margin-right: auto;
  }
  :deep(#related-resources),
  :deep(#authors) {
    width: var(--content-width);
    margin-left: auto;
    margin-right: auto;
  }
  #chart-figure {
    display: block;
    width: var(--content-width);
    max-width: 1500px;
    margin-top: 1vh;
    margin-bottom: 1vh;
  }
  #chart-container {
    min-height: 700px;
    height: 75vh;
    width: 100%;
    @media screen and (max-height: 770px) {
        height: 120vh;
    }
    @media screen and (max-width: 600px) {
        height: 100vh;
    }
  }
  #caption-container {
    display: block;
    margin-top: 1rem;
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
      1px 2px 2px hsl(0deg 0% 40% / 0.47);
    @media screen and (max-width: 600px) {
      margin-top: 0rem;
      margin-bottom: 0.1rem;
    }
  }
  .button:hover {
    background-color: $darkGrey;
    color: white;
    box-shadow:
      3px 6px 6px hsl(0deg 0% 35% / 0.41);
    @media screen and (max-width: 600px) {
      background-color: white;
      color: black;
      box-shadow:
      1px 2px 2px hsl(0deg 0% 35% / 0.47);
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
        font-size: 1.4em;
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
