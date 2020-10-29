<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.1.0" xmlns:se="http://www.opengis.net/se" xmlns:ogc="http://www.opengis.net/ogc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" xmlns:xlink="http://www.w3.org/1999/xlink">
  <NamedLayer>
    <se:Name>Amenaza_Cotopaxi</se:Name>
    <UserStyle>
      <se:Name>Amenaza_Cotopaxi</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:Name>Flujo de lahares</se:Name>
          <se:Description>
            <se:Title>Flujo de lahares</se:Title>
          </se:Description>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>Leyenda</ogc:PropertyName>
              <ogc:Literal>Esta zona, de color gris oscuro, tiene una alta probabilidad de ser afectada por flujos de lodo y escombro o lahares en caso de que ocurra una erupción moderada a grande (VEI 3-4 o VEI >4)</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#676767</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.4</se:SvgParameter>
            </se:Fill>
            <se:Stroke>
              <se:SvgParameter name="stroke">#f7f7f7</se:SvgParameter>
              <se:SvgParameter name="stroke-width">1</se:SvgParameter>
              <se:SvgParameter name="stroke-linejoin">bevel</se:SvgParameter>
            </se:Stroke>
          </se:PolygonSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>Flujo de lahares</se:Name>
          <se:Description>
            <se:Title>Flujo de lahares</se:Title>
          </se:Description>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>Leyenda</ogc:PropertyName>
              <ogc:Literal>Esta zona, de color gris oscuro, tiene una alta probabilidad de ser afectada por flujos de lodo y escombro o lahares en caso de que ocurra una erupción moderada a grande (VEI 3-4 o VEI >4). Esta zona ha sido definida en base del mapeo de los depósitos</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#333333</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.4</se:SvgParameter>
            </se:Fill>
          </se:PolygonSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>Flujo de lahares</se:Name>
          <se:Description>
            <se:Title>Flujo de lahares</se:Title>
          </se:Description>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>Leyenda</ogc:PropertyName>
              <ogc:Literal>Esta zona, de color gris oscuro, tiene una alta probabilidad de ser afectada por flujos de lodo y escombro o lahares en caso de que ocurra una erupción moderada a grande (VEI 3-4 o VEI>4). Esta zona ha sido definida en base a los depósitos dejados por</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#323232</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.4</se:SvgParameter>
            </se:Fill>
            <se:Stroke>
              <se:SvgParameter name="stroke">#232323</se:SvgParameter>
              <se:SvgParameter name="stroke-width">0.2</se:SvgParameter>
              <se:SvgParameter name="stroke-linejoin">bevel</se:SvgParameter>
            </se:Stroke>
          </se:PolygonSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>Zona de lava de menor peligro</se:Name>
          <se:Description>
            <se:Title>Zona de lava de menor peligro</se:Title>
          </se:Description>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>Leyenda</ogc:PropertyName>
              <ogc:Literal>Zona de menor peligro.- Se representa con el color rosado y corresponde a las laderas inferiores del colapso, hasta inclusive los flancos inferiores de los volcanes vecinos, Sincholagua, Rumiñahui y Pasochoa.Esta zona tiene una menor probabilidad de ser</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#ff9698</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.4</se:SvgParameter>
            </se:Fill>
          </se:PolygonSymbolizer>
        </se:Rule>
        <se:Rule>
          <se:Name>Zona de lava de mayor peligro</se:Name>
          <se:Description>
            <se:Title>Zona de lava de mayor peligro</se:Title>
          </se:Description>
          <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
            <ogc:PropertyIsEqualTo>
              <ogc:PropertyName>Leyenda</ogc:PropertyName>
              <ogc:Literal>Zonas de Mayor Peligro: Se representa con el color rojo intenso y corresponde a la zona cercana al volcán. Esta zona tiene una alta probabilidad de ser afectada por flujos piroclásticos, flujos de lava y/o lahares en caso de que ocurra una erupción mo</ogc:Literal>
            </ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <se:PolygonSymbolizer>
            <se:Fill>
              <se:SvgParameter name="fill">#fa0000</se:SvgParameter>
              <se:SvgParameter name="fill-opacity">0.4</se:SvgParameter>
            </se:Fill>
          </se:PolygonSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>