<?xml version="1.0" encoding="utf-8" ?>
<!--
    Application Description Language framework
    base-type-include.xslt
    
    (c) 2007 Cygnet Solutions Ltd
    
    An xsl transform intended to be included into other XSL stylesheets,
    intended to keep lookup of the ADL base type from ADL properties in
    one place for ease of maintenance
    
    $Author: sb $
    $Revision: 1.2 $
    $Date: 2008-02-04 15:53:32 $
  -->

<xsl:stylesheet version="1.0"
  xmlns="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="adl">


  <!-- return the base ADL type of the property which is passed as a parameter -->
  <xsl:template name="base-type">
    <xsl:param name="property"/>
    <xsl:choose>
      <xsl:when test="$property/@type='defined'">
        <xsl:variable name="definition">
          <xsl:value-of select="$property/@typedef"/>
        </xsl:variable>
        <xsl:value-of select="/adl:application/adl:typedef[@name=$definition]/@type"/>
      </xsl:when>
      <xsl:when test="$property/@type='serial'">integer</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$property/@type"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- return the size of the type of the property which is passed as a parameter -->
  <xsl:template name="base-size">
    <xsl:param name="property"/>
    <xsl:choose>
      <xsl:when test="$property/@type='defined'">
        <xsl:variable name="definition">
          <xsl:value-of select="$property/@typedef"/>
        </xsl:variable>
        <xsl:value-of select="/adl:application/adl:typedef[@name=$definition]/@size"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$property/@size"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
