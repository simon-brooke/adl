<?xml version="1.0" encoding="UTF-8" ?>
<!--
    Application Description Language framework
    csharp-type-include.xslt
    
    (c) 2007 Cygnet Solutions Ltd
    
    An XSL transform intended to be included into other XSL stylesheets,
    intended to keep lookup of the C# type from ADL properties in
    one place for ease of maintenance
    
    $Author: sb $
    $Revision: 1.2 $
    $Date: 2008-02-07 16:35:00 $
  -->

<xsl:stylesheet version="1.0"
  xmlns="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="adl">

  <xsl:include href="base-type-include.xslt"/>
  
  <!-- return the C# type of the property which is passed as a parameter -->
  <xsl:template name="csharp-type">
    <xsl:param name="property"/>
    <xsl:variable name="base-type">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" select="$property"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$base-type = 'link'">
        ICollection&lt;<xsl:value-of select="@entity"/>&gt;
      </xsl:when>
      <xsl:when test="$base-type = 'list'">
        ICollection&lt;<xsl:value-of select="@entity"/>&gt;
      </xsl:when>
      <xsl:when test="$base-type = 'date'">DateTime</xsl:when>
      <xsl:when test="$base-type = 'time'">DateTime</xsl:when>
      <xsl:when test="$base-type = 'string'">String</xsl:when>
      <xsl:when test="$base-type = 'text'">String</xsl:when>
      <xsl:when test="$base-type = 'boolean'">bool</xsl:when>
      <xsl:when test="$base-type = 'timestamp'">DateTime</xsl:when>
      <xsl:when test="$base-type = 'integer'">int</xsl:when>
      <xsl:when test="$base-type = 'real'">double</xsl:when>
      <xsl:when test="$base-type = 'money'">Decimal</xsl:when>
      <xsl:when test="$base-type = 'entity'">
        <xsl:value-of select="$property/@entity"/>
      </xsl:when>
      <xsl:otherwise>[unknown?]</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
