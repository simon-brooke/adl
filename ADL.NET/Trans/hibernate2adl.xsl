<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="urn:nhibernate-mapping-2.2">
  <!--
      Application Description Framework
      hibernate2adl.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Transforms hibernate mapping file into partial ADL file. Not complete,
      because the whole point of having an ADL is that the hibernate mapping
      is not sufficiently rich.
      
      $Author: af $
      $Revision: 1.1 $
  -->

  <xsl:output indent="yes" method="xml" encoding="utf-8" doctype-system="file:../j2adl.dtd"/>
  
  <xsl:template match="hibernate-mapping">
    <application name="unset" version="unset">
      <xsl:apply-templates select="class"/>
    </application>  
  </xsl:template>

  <xsl:template match="class">
    <entity>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </entity>
  </xsl:template>

  <xsl:template match="property">
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="@type = 'DateTime'">date</xsl:when>
          <xsl:when test="@type = 'String'">string</xsl:when>
          <xsl:when test="@type = 'bool'">boolean</xsl:when>
          <xsl:when test="@type = 'TimeStamp'">timestamp</xsl:when>
          <xsl:when test="@type = 'int'">integer</xsl:when>
          <xsl:otherwise>[unknown?]</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="required">
        <xsl:choose>
          <xsl:when test="@not-null = 'true'">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="size">
        <xsl:value-of select="@length"/>
      </xsl:attribute> 
    </property>

  </xsl:template>

  <xsl:template match="id">
    <property distinct="system" required="true">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="@type = 'DateTime'">date</xsl:when>
          <xsl:when test="@type = 'String'">string</xsl:when>
          <xsl:when test="@type = 'bool'">boolean</xsl:when>
          <xsl:when test="@type = 'TimeStamp'">timestamp</xsl:when>
          <xsl:when test="@type = 'int'">integer</xsl:when>
          <xsl:otherwise>[unknown?]</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="size">
        <xsl:value-of select="@length"/>
      </xsl:attribute>
    </property>
  </xsl:template>

  <xsl:template match="many-to-one">
    <property type="entity">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="entity">
        <xsl:value-of select="@class"/>
      </xsl:attribute>
    </property>
  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
    
  </xsl:template>
</xsl:stylesheet>