<?xml version="1.0" encoding="UTF-8"?>
<sld:StyledLayerDescriptor version="1.0.0"
    xmlns:sld="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <sld:NamedLayer>
    <sld:Name>gtopo</sld:Name>
    <sld:UserStyle>
      <sld:Title>SLD 1.0 prefixed</sld:Title>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:Opacity>0.8</sld:Opacity>
            <sld:ColorMap>
              <sld:ColorMapEntry color="#0000FF" quantity="70" label="Low"/>
              <sld:ColorMapEntry color="#FFFF00" quantity="170" label="Mid"/>
              <sld:ColorMapEntry color="#FF0000" quantity="256" label="High"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </sld:NamedLayer>
</sld:StyledLayerDescriptor>
