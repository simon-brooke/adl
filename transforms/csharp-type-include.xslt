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
    $Date: 2008-10-02 10:52:40 $
  -->

<xsl:stylesheet version="1.0"
  xmlns="http://libs.cygnets.co.uk/adl/1.1/"
  xmlns:adl="http://libs.cygnets.co.uk/adl/1.1/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="adl">

  <xsl:include href="base-type-include.xslt"/>
  
  <!-- return the primitive C# type of the property which is passed as 
  a parameter - i.e. if csharp-type is an entity, then the csharp-type 
  of the keyfield of that entity, and so on. -->
  <xsl:template name="csharp-base-type">
    <xsl:param name="property"/>
    <xsl:param name="entityns"/>
    <xsl:choose>
      <xsl:when test="$property/@type = 'entity'">
        <xsl:variable name="entityname" select="$property/@entity"/>
        <xsl:choose>
          <xsl:when test="//adl:entity[@name=$entityname]/adl:key/adl:property">
            <!-- recurse... -->
            <xsl:call-template name="csharp-base-type">
              <xsl:with-param name="property" 
                              select="//adl:entity[@name=$entityname]/adl:key/adl:property[position()=1]"/>
              <xsl:with-param name="entityns" select="$entityns"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              ADL: ERROR: could not find C# base type of property <xsl:value-of select="$property/@name"/>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="csharp-type">
          <xsl:with-param name="property" select="$property"/>
          <xsl:with-param name="entityns" select="$entityns"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- return the C# type of the property which is passed as a parameter -->
  <xsl:template name="csharp-type">
    <xsl:param name="property"/>
    <xsl:param name="entityns"/>
    <xsl:variable name="base-type">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" select="$property"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$property/@type = 'message'">Message</xsl:when>
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
      <xsl:when test="$base-type = 'boolean'">Boolean</xsl:when>
      <xsl:when test="$base-type = 'timestamp'">DateTime</xsl:when>
      <xsl:when test="$base-type = 'integer'">int</xsl:when>
      <xsl:when test="$base-type = 'real'">double</xsl:when>
      <xsl:when test="$base-type = 'money'">Decimal</xsl:when>
      <xsl:when test="$base-type = 'entity'">
        <xsl:choose>
          <xsl:when test="$entityns">
            <xsl:value-of select="concat( $entityns, '.', $property/@entity)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$property/@entity"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>[unknown?]</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet> 
