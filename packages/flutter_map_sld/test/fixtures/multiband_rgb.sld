<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
    xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
    xmlns="http://www.opengis.net/sld"
    xmlns:ogc="http://www.opengis.net/ogc"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>satellite</Name>
    <UserStyle>
      <Title>RGB band selection</Title>
      <FeatureTypeStyle>
        <Rule>
          <RasterSymbolizer>
            <ChannelSelection>
              <RedChannel>
                <SourceChannelName>1</SourceChannelName>
                <ContrastEnhancement>
                  <Normalize/>
                  <GammaValue>1.2</GammaValue>
                </ContrastEnhancement>
              </RedChannel>
              <GreenChannel>
                <SourceChannelName>2</SourceChannelName>
              </GreenChannel>
              <BlueChannel>
                <SourceChannelName>3</SourceChannelName>
              </BlueChannel>
            </ChannelSelection>
            <ContrastEnhancement>
              <Histogram/>
            </ContrastEnhancement>
          </RasterSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
