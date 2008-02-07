<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns="http://cygnets.co.uk/schemas/adl-1.2" 
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
      C1873 SRU Hospitality
      adl2mssql.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Convert ADL to MS-SQL
      
      $Author: sb $
      $Revision: 1.5 $
  -->
    
  <xsl:output indent="no" encoding="UTF-8" method="text"/>
  <xsl:include href="base-type-include.xslt"/>

  <!-- 
      The convention to use for naming auto-generated abstract primary keys. Known values are
      Id - the autogenerated primary key, if any, is called just 'Id'
      Name - the autogenerated primary key has the same name as the entity
      NameId - the name of the auto generated primary key is the name of the entity followed by 'Id'
      Name_Id - the name of the auto generated primary key is the name of the entity followed by '_Id'  
    -->
  <xsl:param name="abstract-key-name-convention" select="Id"/>

  <xsl:template match="adl:application"> 
        -------------------------------------------------------------------------------------------------
        --
        --    Database for application <xsl:value-of select="@name"/> version <xsl:value-of select="@version"/>
        --    Generated for MS-SQL 2000+ using adl2mssql.xsl $Revision: 1.5 $
        --
        --    Code generator (c) 2007 Cygnet Solutions Ltd
        --
        -------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------
        --    authentication roles
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="adl:group"/>

        -------------------------------------------------------------------------------------------------
        --    primary tables, views and permissions
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="adl:entity" mode="table"/>

        -------------------------------------------------------------------------------------------------
        --    link tables  
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="adl:entity" mode="links"/>

        -------------------------------------------------------------------------------------------------
        --    primary referential integrity constraints
        -------------------------------------------------------------------------------------------------
      <xsl:for-each select="adl:entity[ not(@foreign='true')]">
        <xsl:variable name="nearside" select="@name"/>
        <xsl:for-each select="property[@type='entity']">
          <xsl:variable name="farside" select="@entity"/>
          <xsl:variable name="keyfield" select="@name"/>
          <xsl:choose>
            <xsl:when test="//adl:entity[@name=$farside]/adl:property[@farkey=$keyfield and @entity=$nearside]">
              <!-- there's a 'list' property pointing the other way; let it do the heavy hauling -->
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$nearside"/>
                <xsl:with-param name="farside" select="$farside"/>
                <xsl:with-param name="keyfield" select="$keyfield"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="adl:property[@type='list']">
          <xsl:variable name="farkey">
            <xsl:choose>
              <xsl:when test="@farkey">
                <xsl:value-of select="@farkey"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="../@name"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:call-template name="foreignkey">
            <xsl:with-param name="nearside" select="@entity"/>
            <xsl:with-param name="farside" select="../@name"/>
            <xsl:with-param name="keyfield" select="$farkey"/>
            <xsl:with-param name="ondelete">
              <xsl:choose>
                <xsl:when test="@cascade='all'">CASCADE</xsl:when>
                <xsl:when test="@cascade='all-delete-orphan'">CASCADE</xsl:when>
                <xsl:when test="@cascade='delete'">CASCADE</xsl:when>
                <xsl:otherwise>NO ACTION</xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:for-each>
      
        -------------------------------------------------------------------------------------------------
        --    end of file
        -------------------------------------------------------------------------------------------------
    </xsl:template>
    
    <xsl:template match="adl:group">
        execute sp_addrole @rolename = '<xsl:value-of select="@name"/>' 
        
        GO
    </xsl:template>
    
    <!-- generate a foreign key referential integrity check -->
    <xsl:template name="foreignkey">
      <xsl:param name="nearside"/>
      <xsl:param name="farside"/>
      <xsl:param name="keyfield"/>
      <xsl:param name="ondelete" select="'NO ACTION'"/>
        <!-- set up referential integrity constraints for primary tables -->
        ALTER TABLE "<xsl:value-of select="$nearside"/>"
            ADD FOREIGN KEY ( "<xsl:value-of select="$keyfield"/>") 
            REFERENCES "<xsl:value-of select="$farside"/>" ON DELETE <xsl:value-of select="$ondelete"/>
            
        GO
    </xsl:template>

  <!-- don't generate foreign tables - although we will generate ref integ constraints for them -->
  <xsl:template match="adl:entity[@foreign='true']" mode="table"/> 

  <xsl:template match="adl:entity" mode="table">
    <xsl:variable name="table">
      <xsl:choose>
        <xsl:when test="@table">
          <xsl:value-of select="@table"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

        -------------------------------------------------------------------------------------------------
        --    primary table <xsl:value-of select="$table"/>
        -------------------------------------------------------------------------------------------------
        CREATE TABLE  "<xsl:value-of select="$table"/>"
        (
          <xsl:for-each select="descendant::adl:property[@type!='link' and @type != 'list']">
            <xsl:apply-templates select="."/><xsl:if test="position() != last()">,</xsl:if>
          </xsl:for-each>
          <xsl:apply-templates select="adl:key"/>
        )

        GO

        ----  permissions  ------------------------------------------------------------------------------
    <xsl:for-each select="adl:permission">
        <xsl:call-template name="permission">
          <xsl:with-param name="table" select="$table"/>
        </xsl:call-template>
      </xsl:for-each>
    
  </xsl:template>

  <xsl:template match="adl:key">
    <xsl:if test="adl:property">
          , 
          PRIMARY KEY( <xsl:for-each select="adl:property">"<xsl:value-of select="@name"/>"<xsl:if test="position() != last()">, </xsl:if></xsl:for-each>)
    </xsl:if>
  </xsl:template>

  <xsl:template name="distinctfield">
    <xsl:param name="table"/>
    <xsl:param name="alias"/>
    <!-- 
            print the names of the distinguishing fields in this table,
            concatenating into a single string. 
        -->
    <xsl:for-each select="/application/entity[@name=$table]">
      <xsl:for-each select="property[@distinct='user' or @distinct='all']">
        <xsl:choose>
          <xsl:when test="@type='entity'">
            <xsl:call-template name="distinctfield">
              <xsl:with-param name="table" select="@entity"/>
              <xsl:with-param name="alias" select="concat( $alias, '_', @name)"></xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            "<xsl:value-of select="$alias"/>"."<xsl:value-of
                        select="@name"/>"<xsl:if test="position() != last()"> + ' ' + </xsl:if>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!-- fix up linking tables. Donoe after all primary tables have been created, 
  because otherwise some links may fail -->
  <xsl:template match="adl:entity" mode="links">
    <xsl:variable name="table" select="@name"/>
    <xsl:for-each select="adl:property[@type='link']">
      <xsl:call-template name="linktable">
        <xsl:with-param name="nearside" select="$table"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="permission">
    <xsl:param name="table"/>
    <!-- decode the permissions for a table -->
    <xsl:choose>
      <xsl:when test="@permission='read'">
        GRANT SELECT ON "<xsl:value-of
                select="$table"/>" TO <xsl:value-of select="@group"/>

        GO
      </xsl:when>
      <xsl:when test="@permission='insert'">
        GRANT INSERT ON "<xsl:value-of
                select="$table"/>" TO <xsl:value-of select="@group"/>

        GO
      </xsl:when>
      <xsl:when test="@permission='noedit'">
        GRANT SELECT, INSERT ON "<xsl:value-of
                select="$table"/>" TO <xsl:value-of select="@group"/>

        GO
      </xsl:when>
      <xsl:when test="@permission='edit'">
        GRANT SELECT, INSERT, UPDATE ON "<xsl:value-of
                select="$table"/>" TO <xsl:value-of select="@group"/>

        GO
      </xsl:when>
      <xsl:when test="@permission='all'">
        GRANT SELECT, INSERT, UPDATE, DELETE ON "<xsl:value-of
                select="$table"/>" TO <xsl:value-of select="@group"/>

        GO
      </xsl:when>
      <xsl:otherwise>
        REVOKE ALL ON "<xsl:value-of
                select="$table"/>" FROM <xsl:value-of select="@group"/>

        GO
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>
            
    </xsl:text>
  </xsl:template>


  <xsl:template name="linktable">
        <xsl:param name="nearside"/>
      <!-- This is tricky. For any many-to-many relationship between two 
      entities, we only want to create one link table, even if (as should be) 
      a property of type 'link' has been declared at both ends -->
      <xsl:variable name="farside">
        <xsl:choose>
          <xsl:when test="@entity = $nearside">
            <xsl:value-of select="concat( @entity, '_1')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@entity"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="comparison">
        <xsl:call-template name="stringcompare">
          <xsl:with-param name="node1" select="$nearside"/>
          <xsl:with-param name="node2" select="@entity"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="farentity" select="/application/entity[@name=$farside]"/>
      
      <!-- Problems with responsibility for generating link tables:
           @entity = <xsl:value-of select="@entity"/>
           $nearside = <xsl:value-of select="$nearside"/>
           $farside = <xsl:value-of select="$farside"/>
           $farentity = <xsl:value-of select="count( $farentity/property)"/>
           farlink = <xsl:value-of select="$farentity/property[@type='link' and @entity=$nearside]/@name"/>
           comparison = '<xsl:value-of select="$comparison"/>' -->

      <xsl:variable name="myresponsibility">
        <xsl:choose>
          <!-- if we could use the compare( string, string) function this would be a lot simpler, but 
          unfortunately that's in XSL 2.0, and neither NAnt nor Visual Studio can manage that -->
          <!-- if the link is back to me, then obviously I'm responsible -->
          <xsl:when test="$comparison = 0">true</xsl:when>
          <!-- generally, the entity whose name is later in the default collating sequence
          shall not be responsible. -->
          <xsl:when test="$comparison = -1">true</xsl:when>
            <!-- However if the one that is earlier doesn't have a 'link' 
          property for this join, however, then later end will have to do it -->
          <xsl:when test="$comparison = 1">
            <xsl:choose>
              <!-- the far side is doing it... -->
              <xsl:when test="$farentity/property[@type='link' and @entity=$nearside]">false</xsl:when>
              <xsl:otherwise>true</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="tablename">
        <xsl:choose>
          <xsl:when test="$comparison =-1">
            <xsl:value-of select="concat( 'LN_', $nearside, '_', @entity)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat( 'LN_', @entity, '_', $nearside)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="$myresponsibility='true'">
          <!-- create a linking table -->

        -------------------------------------------------------------------------------------------------
        --    link table joining <xsl:value-of select="$nearside"/> with <xsl:value-of select="@entity"/>
        -------------------------------------------------------------------------------------------------
        CREATE TABLE "<xsl:value-of select="$tablename"/>"
        (
          "<xsl:value-of select="$nearside"/>Id" INT NOT NULL,
          "<xsl:value-of select="$farside"/>Id" INT NOT NULL,
        )

        GO
          <xsl:text>
            
          </xsl:text>
        ----  permissions  ------------------------------------------------------------------------------
          <xsl:for-each select="../permission">
            <xsl:call-template name="permission">
              <xsl:with-param name="table" select="$tablename"/>
            </xsl:call-template>
          </xsl:for-each>
          <xsl:text>
            
          </xsl:text>
        ----  referential integrity  --------------------------------------------------------------------
          <xsl:choose>
            <xsl:when test="$nearside=@entity">
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$tablename"/>
                <xsl:with-param name="farside" select="$nearside"/>
                <xsl:with-param name="keyfield" select="concat( $nearside, 'Id')"/>
                <xsl:with-param name="ondelete" select="'NO ACTION'"/>
              </xsl:call-template>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$tablename"/>
                <xsl:with-param name="farside" select="$nearside"/>
                <xsl:with-param name="keyfield" select="concat( $farside, 'Id')"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$tablename"/>
                <xsl:with-param name="farside" select="$nearside"/>
                <xsl:with-param name="keyfield" select="concat( $nearside, 'Id')"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$tablename"/>
                <xsl:with-param name="farside" select="@entity"/>
                <xsl:with-param name="keyfield" select="concat( @entity, 'Id')"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
        -- Suppressing generation of <xsl:value-of select="$tablename"/>, as it is not my responsibility
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="myresponsibility='true'">
      </xsl:if>
    </xsl:template>

  <xsl:template match="adl:property[@type='list']">
        -- Suppressing output of property <xsl:value-of select="@name"/>,
        -- as it is the 'one' end of a one-to-many relationship
  </xsl:template>

  <xsl:template match="adl:property[@type='serial']">
            <xsl:call-template name="property-name">
      <xsl:with-param name="property" select="."/>
    </xsl:call-template><xsl:text> INT IDENTITY( 1, 1)</xsl:text>
    <xsl:message terminate="no">
      ADL: WARNING: type='serial' is deprecated; add a generator with type='native' instead
    </xsl:message>
  </xsl:template>

  <xsl:template match="adl:generator[@action='native']">
    IDENTITY( 1, 1)
  </xsl:template>
  <xsl:template match="adl:generator"/>

  <!-- the grand unified property handler, using the sql-type template to 
  generate the correct types for each field -->
  <xsl:template match="adl:property">
    <xsl:variable name="column">
      <xsl:call-template name="property-name">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="type">
      <xsl:call-template name="sql-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="base-type">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="generator">
      <xsl:apply-templates select="adl:generator"/>
    </xsl:variable>
          "<xsl:value-of select="$column"/>" <xsl:value-of 
                select="concat( normalize-space( $type), ' ', normalize-space( $generator))"/><xsl:if
                test="@required='true'"> NOT NULL</xsl:if><xsl:if
            test="string(@default)"> DEFAULT <xsl:choose>
              <xsl:when test="$base-type = 'integer' or $base-type = 'real' or $base-type = 'money'">
                <xsl:value-of select="@default"/>
              </xsl:when>
              <xsl:otherwise>'<xsl:value-of select="@default"/>'</xsl:otherwise>
            </xsl:choose>
    </xsl:if>

  </xsl:template>
  
  <!-- properties of type 'entity' are supposed to be being handled by the 
  grand unified property handler. Unfortunately it gets them wrong and I'm not 
  sure why. So temporarily this special case template fixes the problem. TODO: 
  work out what's wrong with the grand unified version -->
  <xsl:template match="adl:property[@type='entity']">
    <xsl:variable name="column">
      <xsl:call-template name="property-name">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="type">
      <xsl:call-template name="sql-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
          "<xsl:value-of select="$column"/>" <xsl:value-of select="$type"/><xsl:if 
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
                test="@required='true'"> NOT NULL</xsl:if>
  </xsl:template>


  <!-- consistent, repeatable way of getting the column name for a given property -->
  <xsl:template name="property-name">
    <xsl:param name="property"/>
    <xsl:choose>
      <xsl:when test="$property/@column">
        <xsl:value-of select="$property/@column"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$property/@name"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="primary-key-name">
    <xsl:param name="entityname"/>
    <xsl:choose>
      <xsl:when test="//adl:entity[@name=$entityname]/@natural-key">
        <xsl:value-of select="//adl:entity[@name=$entityname]/@natural-key"/>
      </xsl:when>
      <xsl:when test="//adl:entity[@name=$entityname]/key">
        <xsl:choose>
          <xsl:when test="count(//adl:entity[@name=$entityname]/adl:key/adl:property) &gt; 1">
            <xsl:message terminate="no">
              ADL: WARNING: entity '<xsl:value-of select="$entityname"/>' has a compound primary key;
              adl2mssql is not yet clever enough to generate appropriate code
            </xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="//adl:entity[@name=$entityname]/adl:key/adl:property[position()=1]"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$abstract-key-name-convention='Name'">
            <xsl:value-of select="@name"/>
          </xsl:when>
          <xsl:when test="$abstract-key-name-convention = 'NameId'">
            <xsl:value-of select="concat( $entityname, 'Id')"/>
          </xsl:when>
          <xsl:when test="$abstract-key-name-convention = 'Name_Id'">
            <xsl:value-of select="concat( $entityname, '_Id')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'Id'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- return the SQL type of the property which is passed as a parameter -->
  <xsl:template name="sql-type">
    <xsl:param name="property"/>
    <xsl:variable name="base-type">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" select="$property"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="base-size">
      <xsl:call-template name="base-size">
        <xsl:with-param name="property" select="$property"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$base-type = 'entity'">
        <xsl:variable name="entity" select="$property/@entity"/>
        <xsl:choose>
          <xsl:when test="//adl:entity[@name=$entity]">
            <xsl:choose>
              <xsl:when test="//adl:entity[@name=$entity]/adl:key/adl:property">
                <xsl:call-template name="sql-type">
                  <xsl:with-param name="property"
                                  select="//adl:entity[@name=$entity]/adl:key/adl:property[position()=1]"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message terminate="yes">
                  ADL: ERROR: property '<xsl:value-of select="$property/@name"/>' refers to
                  entity '<xsl:value-of select="$property/@entity"/>', but this entity has not key.
                </xsl:message>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              ADL: ERROR: property '<xsl:value-of select="$property/@name"/>' refers to 
              entity '<xsl:value-of select="$property/@entity"/>', but no such entity exists.
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$base-type = 'date'">DATETIME</xsl:when>
      <xsl:when test="$base-type = 'time'">DATETIME</xsl:when>
      <!-- TODO: if the type was 'defined' then the size should probably come from the typedef -->
      <xsl:when test="$base-type = 'string'">VARCHAR( <xsl:value-of select="$base-size"/>)</xsl:when>
      <xsl:when test="$base-type = 'text'">TEXT</xsl:when>
      <xsl:when test="$base-type = 'boolean'">BIT</xsl:when>
      <xsl:when test="$base-type = 'timestamp'">TIMESTAMP</xsl:when>
      <xsl:when test="$base-type = 'integer'">INT</xsl:when>
      <xsl:when test="$base-type = 'real'">DOUBLE PRECISION</xsl:when>
      <xsl:when test="$base-type = 'money'">DECIMAL</xsl:when>
      <xsl:when test="$base-type = 'serial'">INT IDENTITY( 1, 1)</xsl:when>
      <xsl:otherwise>[sql:unknown? [<xsl:value-of select="$base-type"/>]]</xsl:otherwise>
    </xsl:choose>

  </xsl:template>


  <!-- horrible, horrible hackery. Compare two strings and return 
        * 0 if they are identical, 
        * -1 if the first is earlier in the default collating sequence, 
        * 1 if the first is later. 
    In XSL 2.0 this could be done using the compare(string, string) function. -->
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
