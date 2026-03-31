<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>dem</Name>
    <UserStyle>
      <Title>Scale-dependent raster</Title>
      <FeatureTypeStyle>
        <Rule>
          <Name>overview</Name>
          <MaxScaleDenominator>500000</MaxScaleDenominator>
          <RasterSymbolizer>
            <ColorMap>
              <ColorMapEntry color="#000000" quantity="0"/>
              <ColorMapEntry color="#FFFFFF" quantity="1000"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
        <Rule>
          <Name>detail</Name>
          <MinScaleDenominator>500000</MinScaleDenominator>
          <RasterSymbolizer>
            <ColorMap>
              <ColorMapEntry color="#0000FF" quantity="0"/>
              <ColorMapEntry color="#00FF00" quantity="500"/>
              <ColorMapEntry color="#FF0000" quantity="1000"/>
            </ColorMap>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
