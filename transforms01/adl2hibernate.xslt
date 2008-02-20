<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
  xmlns="urn:nhibernate-mapping-2.2"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
      Application Description Framework
      adl2hibernate.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Transform ADL to Hibernate
      
      $Author: sb $
      $Revision: 1.8 $
  -->

  <!-- 
      The convention to use for naming auto-generated abstract primary keys. Known values are
      Id - the autogenerated primary key, if any, is called just 'Id'
      Name - the autogenerated primary key has the same name as the entity
      NameId - the name of the auto generated primary key is the name of the entity followed by 'Id'
      Name_Id - the name of the auto generated primary key is the name of the entity followed by '_Id'  
    -->
  <xsl:param name="abstract-key-name-convention" select="Id"/>
  <xsl:param name="namespace"/>
  <xsl:param name="assembly"/>
  <xsl:param name="database"/>
  
  <xsl:output indent="no" method="xml" encoding="UTF-8"/>
  <!-- NOTE! indent="no" because hibernate falls over if there is whitespace inside
    a 'key' or 'one-to-many' element, and the printer used by the NAnt 'style' task
    does not tag-minimize on output. If you change this the build will break, you
    have been warned! -->

  <xsl:include href="csharp-type-include.xslt"/>

  <xsl:variable name="dbprefix">
    <xsl:choose>
      <xsl:when test="string-length( $database) > 0">
        <xsl:value-of select="concat( $database, '.dbo.')"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:variable>

  <xsl:template match="adl:application">
      <hibernate-mapping>
        <xsl:attribute name="namespace">
          <xsl:value-of select="$namespace"/>
        </xsl:attribute>
        <xsl:attribute name="assembly">
          <xsl:value-of select="$assembly"/>
        </xsl:attribute>
        <xsl:comment>
    ***************************************************************************
    *
    *   Application Description Language framework
    *	  <xsl:value-of select="@name"/>.auto.hbm.xml
    *
    *	  ©2007 Cygnet Solutions Ltd
    *
    *	  THIS FILE IS AUTOMATICALLY GENERATED AND SHOULD NOT
    *	  BE MANUALLY EDITED.
    *
    *	  Generated using adl2hibernate.xslt revision <xsl:value-of select="substring('$Revision: 1.8 $', 12)"/>
    *
    ***************************************************************************
        </xsl:comment>
        
        <xsl:apply-templates select="adl:entity"/>
      </hibernate-mapping>

  </xsl:template>

  <xsl:template match="adl:entity[@foreign='true']"/>

  <xsl:template match="adl:entity">
    <xsl:apply-templates select="adl:documentation"/>
    <xsl:variable name="prefix">
      <xsl:choose>
        <xsl:when test="string-length( $database) &gt; 0">
          <xsl:value-of select="concat( $database, '.dbo.')"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <class>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:choose>
          <xsl:when test="@table">
            <xsl:value-of select="concat( $prefix, '[', @table, ']')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat( $prefix, '[', @name, ']')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="adl:key"/>
      <xsl:apply-templates select="adl:property"/>
    </class>
  </xsl:template>

  <xsl:template match="adl:key">
    <xsl:choose>
      <xsl:when test="count( adl:property) = 0">
      </xsl:when>
      <xsl:when test="count( adl:property) = 1">
        <id>
          <xsl:attribute name="name">
            <xsl:value-of select="adl:property[position()=1]/@name"/>
          </xsl:attribute>
          <xsl:attribute name="column">
            <xsl:choose>
              <xsl:when test="adl:property[position()=1]/@column">
                <xsl:value-of select="adl:property[position()=1]/@column"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="adl:property[position()=1]/@name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="type">
            <xsl:call-template name="csharp-base-type">
              <xsl:with-param name="property" select="adl:property[position()=1]"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:choose>
            <xsl:when test="adl:property[position()=1]/adl:generator">
              <xsl:attribute name="name">
                <xsl:value-of select="adl:property[position()=1]/@name"/>
              </xsl:attribute>
              <xsl:apply-templates select="adl:property[position()=1]/adl:generator"/>
            </xsl:when>
            <xsl:when test="adl:property[position()=1 and @type='entity']">
              <xsl:attribute name="name">
                <xsl:value-of select="concat( adl:property[position()=1]/@name, '_Value')"/>
              </xsl:attribute>
              <xsl:variable name="entityname" select="adl:property[position()=1]/@entity"/>
              <xsl:variable name="farkey">
                <xsl:choose>
                  <xsl:when test="adl:property[position()=1]/@farkey">
                    <xsl:value-of select="adl:property[position()=1]/@farkey"/>
                  </xsl:when>
                  <xsl:when test="//adl:entity[@name=$entityname]/adl:key/adl:property">
                    <xsl:value-of select="//adl:entity[@name=$entityname]/adl:key/adl:property[position()=1]/@name"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'[unkown?]'"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>  
              <generator class="foreign">
                <param name="property">
                  <xsl:value-of select="$farkey"/>
                </param>
              </generator>
            </xsl:when>
            <xsl:otherwise>
              <xsl:comment>TODO: remember you need to deal with this in manually maintained code</xsl:comment>
              <generator class="assigned"/>
            </xsl:otherwise>
          </xsl:choose>
        </id>
        <xsl:if test="adl:property[position()=1 and @type='entity']">
          <xsl:apply-templates select="adl:property[position()=1]"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <composite-id>
          <!-- xsl:attribute name="name">
            <xsl:choose>
              <xsl:when test="$abstract-key-name-convention='Name'">
                <xsl:value-of select="ancestor::adl:entity/@name"/>
              </xsl:when>
              <xsl:when test="$abstract-key-name-convention = 'NameId'">
                <xsl:value-of select="concat( ancestor::adl:entity/@name, 'Id')"/>
              </xsl:when>
              <xsl:when test="$abstract-key-name-convention = 'Name_Id'">
                <xsl:value-of select="concat( ancestor::adl:entity/@name, '_Id')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'Id'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute -->
          <xsl:for-each select="adl:property[not(@type='entity')]">
            <key-property>
              <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:attribute name="column">
                <xsl:choose>
                  <xsl:when test="@column">
                    <xsl:value-of select="@column"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="@name"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <xsl:attribute name="type">
                <xsl:call-template name="csharp-type">
                  <xsl:with-param name="property" select="."/>
                </xsl:call-template>
              </xsl:attribute>
              <xsl:apply-templates select="adl:documentation"/>
            </key-property>
          </xsl:for-each>
          <xsl:for-each select="adl:property[@type='entity']">
            <key-many-to-one>
              <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:attribute name="column">
                <xsl:choose>
                  <xsl:when test="@column">
                    <xsl:value-of select="@column"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="@name"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <xsl:attribute name="class">
                <xsl:value-of select="@entity"/>
              </xsl:attribute>
              <xsl:choose>
                <xsl:when test="@cascade='manual'"/>
                <xsl:when test="@cascade">
                  <xsl:attribute name="cascade">
                    <xsl:value-of select="@cascade"/>
                  </xsl:attribute>
                </xsl:when>
              </xsl:choose>
              <xsl:apply-templates select="adl:documentation"/>
            </key-many-to-one>
          </xsl:for-each>
        </composite-id>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="adl:generator">
    <generator>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="@action='manual'">
            <xsl:value-of select="@class"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@action"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </generator>
  </xsl:template>

  <xsl:template match="adl:property[@concrete='false']">
    <!-- properties which are not concrete are by definition not 
    stored in the database -->
  </xsl:template>

  
  
  <xsl:template match="adl:property[@type='entity']">
    <!-- a property of type entity translates to a Hibernate many-to-one,
      unless it's part of the key, in which case it translates as one-to-one.
      TODO: Check this logic! -->
    <!-- xsl:choose>
      <xsl:when test="parent::adl:key">
        <one-to-one>
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:attribute name="class">
            <xsl:value-of select="@entity"/>
          </xsl:attribute>
          <xsl:if test="@farkey">
            <xsl:attribute name="property-ref">
              <xsl:value-of select="@farkey"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="@cascade='manual'"/>
            <xsl:when test="@cascade">
              <xsl:attribute name="cascade">
                <xsl:value-of select="@cascade"/>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>
          <xsl:apply-templates select="adl:documentation"/>
        </one-to-one>
      </xsl:when>
      <xsl:otherwise -->
        <many-to-one>
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:attribute name="class">
            <xsl:value-of select="@entity"/>
          </xsl:attribute>
          <xsl:attribute name="column">
            <xsl:choose>
              <xsl:when test="@column">
                <xsl:value-of select="@column"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="@farkey">
            <xsl:attribute name="property-ref">
              <xsl:value-of select="@farkey"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="@cascade='manual'"/>
            <xsl:when test="@cascade">
              <xsl:attribute name="cascade">
                <xsl:value-of select="@cascade"/>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>
          <xsl:apply-templates select="adl:documentation"/>
        </many-to-one>
      <!-- /xsl:otherwise>
    </xsl:choose -->
  </xsl:template>

  <xsl:template match="adl:property[@type='list']">
    <xsl:variable name="farent" select="@entity"/>
    <xsl:variable name="nearent" select="ancestor::adl:entity/@name"/>
    <xsl:variable name="farkey">
      <xsl:choose>
        <xsl:when test="@farkey">
          <xsl:value-of select="@farkey"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="ancestor::adl:entity/@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <set>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="inverse">
        <!-- true if the other end of the link is described in the ADL (which it normally will be) -->
        <xsl:choose>
          <xsl:when test="//adl:entity[@name=$farent]/adl:property[@name=$farkey and @entity=$nearent]">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="adl:documentation"/>
      <!-- careful with reformatting here: 
        'The element cannot contain white space. Content model is empty.' -->
      <key><xsl:attribute name="column">
        <!-- this is the name of the farside foreign key field which points to me -->
        <xsl:value-of select="$farkey"/>
        </xsl:attribute></key>
      <one-to-many>
        <xsl:attribute name="class">
          <xsl:value-of select="@entity"/>
        </xsl:attribute>
      </one-to-many>
      <xsl:choose>
        <xsl:when test="@cascade='manual'"/>
        <xsl:when test="@cascade">
          <xsl:attribute name="cascade">
            <xsl:value-of select="@cascade"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </set>
  </xsl:template>

  <xsl:template match="adl:property[@type='link']">
    <!-- a property of type 'link' maps on to a Hibernate set -->
    <xsl:variable name="comparison">
      <xsl:call-template name="stringcompare">
        <xsl:with-param name="node1" select="../@name"/>
        <xsl:with-param name="node2" select="@entity"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="tablename">
      <xsl:choose>
        <xsl:when test="$comparison =-1">
          <xsl:value-of select="concat( $dbprefix, 'ln_', ../@name, '_', @entity)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat( $dbprefix, 'ln_', @entity, '_', ../@name)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <set>
      <xsl:apply-templates select="adl:documentation"/>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="$tablename"/>
      </xsl:attribute>
      <key>
        <xsl:attribute name="column">
          <xsl:value-of select="concat( ../@name, 'Id')"/>
        </xsl:attribute>
      </key>
      <many-to-many>
        <xsl:attribute name="column">
          <xsl:choose>
            <xsl:when test="../@name = @entity">
              <xsl:value-of select="concat( @entity, '_1Id')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat( @entity, 'Id')"/>
            </xsl:otherwise>
          </xsl:choose>          
        </xsl:attribute>
        <xsl:attribute name="class">
          <xsl:value-of select="@entity"/>
        </xsl:attribute>
      </many-to-many>
    </set>
  </xsl:template>
  
  <xsl:template match="adl:property">
    <!-- tricky, this, because we're translating between ADL properties and 
    Hibernate properties, which are (slightly) different. There's potential 
    for confusion -->
    <property>
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:call-template name="csharp-type">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="column">
        <xsl:choose>
          <xsl:when test="@column">
            <xsl:value-of select="@column"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@name"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:apply-templates select="adl:documentation"/>
    </property>
  </xsl:template>

  <xsl:template match="adl:documentation">
    <xsl:comment>
      <xsl:apply-templates/>
    </xsl:comment>
  </xsl:template>

  <!-- 
    horrible, horrible hackery. Compare two strings and return 
        * 0 if they are identical, 
        * -1 if the first is earlier in the default collating sequence, 
        * 1 if the first is later. 
    In XSL 2.0 this could be done using the compare(string, string) function.
    TODO: probably should be an include file
  -->
  <xsl:template name="stringcompare">
    <xsl:param name="node1"/>
    <xsl:param name="node2"/>
    <xsl:choose>
      <xsl:when test="string($node1)=string($node2)">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="$node1 | $node2">
          <xsl:sort select="."/>
          <xsl:if test="position()=1">
            <xsl:choose>
              <xsl:when test="string(.) = string($node1)">
                <xsl:text>-1</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>1</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>