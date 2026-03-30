<?xml version="1.0" encoding="UTF-8"?>
<sld:StyledLayerDescriptor version="1.1.0"
    xmlns:sld="http://www.opengis.net/sld"
    xmlns:se="http://www.opengis.net/se"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <sld:NamedLayer>
    <se:Name>gtopo</se:Name>
    <sld:UserStyle>
      <se:Name>SE 1.1 style</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>0.9</se:Opacity>
            <se:ColorMap type="intervals">
              <se:ColorMapEntry color="#008000" quantity="100" label="Low"/>
              <se:ColorMapEntry color="#FFFF00" quantity="200" label="Mid"/>
              <se:ColorMapEntry color="#FF0000" quantity="300" label="High"/>
            </se:ColorMap>
            <se:ContrastEnhancement>
              <se:Histogram/>
              <se:GammaValue>1.2</se:GammaValue>
            </se:ContrastEnhancement>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </sld:UserStyle>
  </sld:NamedLayer>
</sld:StyledLayerDescriptor>
