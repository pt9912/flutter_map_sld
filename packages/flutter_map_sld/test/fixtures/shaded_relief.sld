<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>terrain</Name>
    <UserStyle>
      <Title>Shaded relief with color ramp</Title>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <ColorMap>
              <ColorMapEntry color="#008000" quantity="0"/>
              <ColorMapEntry color="#663333" quantity="2000"/>
              <ColorMapEntry color="#FFFFFF" quantity="4000"/>
            </ColorMap>
            <ShadedRelief>
              <BrightnessOnly>false</BrightnessOnly>
              <ReliefFactor>55</ReliefFactor>
            </ShadedRelief>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
