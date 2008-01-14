<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:h="urn:nhibernate-mapping-2.2">
  <!--
      Application Description Framework
      hibernate2adl.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Transforms hibernate mapping file into partial ADL file. Not complete,
      because the whole point of having an ADL is that the hibernate mapping
      is not sufficiently rich.
      
      $Author: af $
      $Revision: 1.2 $
  -->

  <xsl:output indent="yes" method="xml" encoding="utf-8" 
    />

  <xsl:variable name="entityns" select="/h:hibernate-mapping/@namespace"/>
  
  <xsl:template match="h:hibernate-mapping">
    <application name="unset" version="unset">
      <xsl:apply-templates select="h:class"/>
    </application>
  </xsl:template>

  <xsl:template match="h:class">
    <entity>
      <xsl:attribute name="name">
        <xsl:call-template name="last-part">
          <xsl:with-param name="full" select="@name"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:apply-templates/>
      <form name="edit" properties="listed">
        <xsl:for-each select="h:property|h:composite-id/*">
          <field>
            <xsl:attribute name="property">
              <xsl:value-of select="@name"/>
            </xsl:attribute>
          </field>
        </xsl:for-each>
      </form>
      <list name="list" onselect="edit" properties="listed">
        <pragma name="with-pagination-control" value="true"/>
        <pragma name="with-can-add" value="true"/>
        <xsl:for-each select="h:property[@type!='list' and @type!='link']|h:composite-id/*">
          <field>
            <xsl:attribute name="property">
              <xsl:value-of select="@name"/>
            </xsl:attribute>
          </field>
        </xsl:for-each>
      </list>
    </entity>
  </xsl:template>

  <xsl:template match="h:property|h:key-property">
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:call-template name="type-attr">
          <xsl:with-param name="t" select="@type" />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="contains(name(..),'composite-id')">
          <xsl:attribute name="distinct">system</xsl:attribute>
          <xsl:attribute name="required">true</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="required">
            <xsl:choose>
              <xsl:when test="@not-null = 'true'">true</xsl:when>
              <xsl:otherwise>false</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </property>
  </xsl:template>

  <xsl:template match="h:id">
    <property distinct="system" required="true">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:call-template name="type-attr">
          <xsl:with-param name="t" select="@type" />
        </xsl:call-template>
      </xsl:attribute>
    </property>
  </xsl:template>

  <xsl:template name="type-attr">
    <xsl:param name="t"/>
    <xsl:choose>
      <xsl:when test="$t = 'DateTime'">date</xsl:when>
      <xsl:when test="$t = 'Decimal'">real</xsl:when>
      <xsl:when test="$t = 'String' or $t='string'">string</xsl:when>
      <xsl:when test="starts-with($t,'String(')">string</xsl:when>
      <xsl:when test="$t = 'bool' or $t='Boolean'">boolean</xsl:when>
      <xsl:when test="$t = 'TimeStamp'">timestamp</xsl:when>
      <xsl:when test="$t = 'int' or $t='Int32'">integer</xsl:when>
      <xsl:when test="substring($t, string-length($t) - 3)='Type'">
        <xsl:value-of select="substring($t, 1, string-length($t)-4)"/>
      </xsl:when>
      <xsl:otherwise>[unknown!<xsl:value-of select="$t"/>]</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="last-part">
    <xsl:param name="full"/>
    <xsl:choose>
      <xsl:when test="starts-with($full, concat($entityns, '.'))">
        <xsl:value-of select="substring($full, string-length($entityns)+2)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$full"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="h:many-to-one|h:key-many-to-one">
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">entity</xsl:attribute>
      <xsl:attribute name="entity">
        <xsl:call-template name="last-part">
          <xsl:with-param name="full" select="@class"/>
        </xsl:call-template>
      </xsl:attribute>

      <xsl:choose>
        <xsl:when test="contains(name(..),'composite-id')">
          <xsl:attribute name="distinct">system</xsl:attribute>
          <xsl:attribute name="required">true</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="required">
            <xsl:choose>
              <xsl:when test="@not-null = 'true'">true</xsl:when>
              <xsl:otherwise>false</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </property>
  </xsl:template>

  <xsl:template match="h:set/h:many-to-many">
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="../@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">link</xsl:attribute>
      <xsl:attribute name="entity">
        <xsl:call-template name="last-part">
          <xsl:with-param name="full" select="@class"/>
        </xsl:call-template>
      </xsl:attribute>
    </property>
  </xsl:template>

  <xsl:template match="h:set/h:one-to-many">
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="../@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">list</xsl:attribute>
      <xsl:attribute name="entity">
        <xsl:call-template name="last-part">
          <xsl:with-param name="full" select="@class"/>
        </xsl:call-template>
      </xsl:attribute>
    </property>
  </xsl:template>

  <!-- xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
    
  </xsl:template -->
</xsl:stylesheet>