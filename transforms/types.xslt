<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns="http://cygnets.co.uk/schemas/adl-1.2"
                xmlns:a="http://cygnets.co.uk/schemas/adl-1.2"
                exclude-result-prefixes="a">
  <!--
      Application Description Framework
      types.xslt
      
      (c) 2008 Cygnet Solutions Ltd
      
      Deals with looking up type information.
      
      $Author: af $
      $Revision: 1.1 $
  -->
  <xsl:output indent="yes" method="xml" encoding="utf-8"/>

  <!-- Convenience (if you can use that word with XSLT) to obtain a type name. -->
  <xsl:template name="type-name">
    <xsl:call-template name="type-attr">
      <xsl:with-param name="attr" select="'name'" />
    </xsl:call-template>
  </xsl:template>

  <!-- Retrieve a particular attribute from a type, possibly recursively through typedefs. -->
  <xsl:template name="type-attr">
    <xsl:param name="attr"/>
    <!-- The attribute we want-->

    <xsl:choose>
      <xsl:when test="name()='type'">
        <xsl:value-of select="@*[name()=$attr]"/>
      </xsl:when>

      <!-- Can we can resolve this immediately? -->
      <xsl:when test="$attr!='name' and @*[name()=$attr]">
        <xsl:value-of select="@*[name()=$attr]"/>
      </xsl:when>

      <!-- Otherwise look it up in the referred type -->
      <xsl:otherwise>
        <xsl:variable name="typename" select="@type" />
        <xsl:choose>
          <!-- Look up in the source document -->
          <xsl:when test="/a:application/a:type[@name=$typename]|/a:application/a:typedef[@name=$typename]">
            <xsl:for-each select="/a:application/a:type[@name=$typename]|/a:application/a:typedef[@name=$typename]">
              <xsl:call-template name="type-attr">
                <xsl:with-param name="attr" select="$attr"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <!-- Look up in global types.xml -->
          <xsl:when test="document('types.xml')/types/*[@name=$typename]">
            <xsl:for-each select="document('types.xml')/types/*[@name=$typename]">
              <xsl:call-template name="type-attr">
                <xsl:with-param name="attr" select="$attr"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <!-- Cannot find the type -->
          <xsl:otherwise>
            <xsl:message terminate="yes">
              Cannot find type "<xsl:value-of select="$typename"/>".
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>