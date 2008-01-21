<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
      C1873 SRU Hospitality
      adl2mssql.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Convert ADL to MS-SQL
      
      $Author: af $
      $Revision: 1.1 $
  -->
    
    <xsl:output indent="no" encoding="utf-8" method="text"/>
    
    <xsl:template match="application"> 
        -------------------------------------------------------------------------------------------------
        --
        --    Database for application <xsl:value-of select="@name"/> version <xsl:value-of select="@version"/>
        --    Generated for MS-SQL 2000+ using adl2mssql.xsl $Revision: 1.1 $
        --
        --    Code generator (c) 2007 Cygnet Solutions Ltd
        --
        -------------------------------------------------------------------------------------------------

        -------------------------------------------------------------------------------------------------
        --    authentication roles
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="group"/>

        -------------------------------------------------------------------------------------------------
        --    tables, views and permissions
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="entity" mode="table"/>

        <xsl:apply-templates select="entity" mode="view"/>

        -------------------------------------------------------------------------------------------------
        --    referential integrity constraints
        -------------------------------------------------------------------------------------------------
            <xsl:for-each select="entity">
              <xsl:variable name="nearside" select="@name"/>
              <xsl:for-each select="property[@type='entity']">
                <xsl:call-template name="referentialintegrity">
                    <xsl:with-param name="nearside" select="$nearside"/>
                </xsl:call-template>
                
            </xsl:for-each>
        </xsl:for-each>
      
        -------------------------------------------------------------------------------------------------
        --    end of file
        -------------------------------------------------------------------------------------------------
    </xsl:template>
    
    <xsl:template match="group">
        execute sp_addrole @rolename = '<xsl:value-of select="@name"/>' 
        
        GO
    </xsl:template>
    
    
    <xsl:template name="referentialintegrity">
        <xsl:param name="nearside"/>
        <!-- set up referential integrity constraints for primary tables -->
        ALTER TABLE "<xsl:value-of select="$nearside"/>"
            ADD FOREIGN KEY ( "<xsl:value-of select="@name"/>") 
            REFERENCES "<xsl:value-of select="@entity"/>" ON DELETE NO ACTION
            
        GO
    </xsl:template>


    <xsl:template match="entity" mode="table">
        <xsl:variable name="table" select="@name"/>

        -------------------------------------------------------------------------------------------------
        --    primary table <xsl:value-of select="@name"/>
        -------------------------------------------------------------------------------------------------
        CREATE TABLE  "<xsl:value-of select="@name"/>"
        (
          <xsl:apply-templates select="property[@type!='link']"/>
          <xsl:value-of select="@name"/>Id INT IDENTITY( 1, 1) PRIMARY KEY
        )
        
        GO

        ----  permissions  ------------------------------------------------------------------------------
        <xsl:for-each select="permission">
          <xsl:call-template name="permission">
            <xsl:with-param name="table" select="$table"/>
          </xsl:call-template>
        </xsl:for-each>

      </xsl:template>
  
      <xsl:template match="entity" mode="view">
        <xsl:variable name="table" select="@name"/>
        -------------------------------------------------------------------------------------------------
        --    convenience view VW_DL_<xsl:value-of select="@name"/> for default list
        -------------------------------------------------------------------------------------------------
        
        CREATE VIEW "VW_DL_<xsl:value-of select="@name"/>" AS
        SELECT "<xsl:value-of select="@name"/>"."<xsl:value-of select="@name"/>Id",
        <xsl:for-each select="property[@type!='link']">
            <xsl:choose>
               <xsl:when test="@type='entity'">
                   <xsl:call-template name="distinctfield">
                       <xsl:with-param name="table" select="@entity"/>
                       <xsl:with-param name="alias" select="@name"/>
                   </xsl:call-template> AS <xsl:value-of select="@name"/></xsl:when>
                <xsl:otherwise>"<xsl:value-of select="$table"/>"."<xsl:value-of select="@name"/>"</xsl:otherwise>
            </xsl:choose><xsl:choose>
                <xsl:when test="position() = last()"></xsl:when>
                <xsl:otherwise>,
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        FROM  "<xsl:value-of select="@name"/>" <xsl:for-each 
          select="property[@type='entity']">, "<xsl:value-of select="@entity"/>" AS "<xsl:value-of select="@name"/>"</xsl:for-each>
        <xsl:text>
        </xsl:text>
        <xsl:for-each select="property[@type='entity']">
            <xsl:choose>
            <xsl:when test="position() = 1">WHERE </xsl:when>
            <xsl:otherwise>AND   </xsl:otherwise>
            </xsl:choose>"<xsl:value-of select="$table"/>"."<xsl:value-of 
                select="@name"/>" = "<xsl:value-of select="@name"/>"."<xsl:value-of select="@entity"/>Id"
        </xsl:for-each>
        
        GO

        ----  permissions  ------------------------------------------------------------------------------
        <xsl:for-each select="permission">
            <xsl:call-template name="viewpermission">
                <xsl:with-param name="table" select="$table"/>
            </xsl:call-template>
        </xsl:for-each>
        
        <!-- link tables -->
        <xsl:for-each select="property[@type='link']">
            <xsl:call-template name="linktable">
                <xsl:with-param name="nearside" select="$table"/>
            </xsl:call-template>
        </xsl:for-each>
        
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
     
    <xsl:template name="permission">
        <xsl:param name="table"/>
        <!-- decode the permissions for a table -->
        <xsl:choose>
            <xsl:when test="@permission='read'">GRANT SELECT ON "<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
            GO</xsl:when>
            <xsl:when test="@permission='insert'">GRANT INSERT ON "<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
            GO</xsl:when>
            <xsl:when test="@permission='noedit'">GRANT SELECT, INSERT ON "<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
            GO</xsl:when>
            <xsl:when test="@permission='edit'">GRANT SELECT, INSERT, UPDATE ON "<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
            GO</xsl:when>
            <xsl:when test="@permission='all'">GRANT SELECT, INSERT, UPDATE, DELETE ON "<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
            GO</xsl:when>
            <xsl:otherwise>REVOKE ALL ON "<xsl:value-of 
                select="$table"/>" FROM <xsl:value-of select="@group"/> 
              
            GO</xsl:otherwise>
        </xsl:choose>
        <xsl:text>
            
        </xsl:text>
    </xsl:template>
     
    <xsl:template name="viewpermission">
        <xsl:param name="table"/>
        <!-- decode the permissions for a convenience view -->
        <xsl:choose>
            <xsl:when test="@permission='none'">REVOKE ALL ON "VW_DL_<xsl:value-of 
                select="$table"/>" FROM <xsl:value-of select="@group"/> 
              
                GO</xsl:when>
            <xsl:when test="@permission='insert'">REVOKE ALL ON "VW_DL_<xsl:value-of 
                select="$table"/>" FROM <xsl:value-of select="@group"/> 
              
                GO</xsl:when>
            <xsl:otherwise>GRANT SELECT ON "VW_DL_<xsl:value-of 
                select="$table"/>" TO <xsl:value-of select="@group"/> 
              
                GO</xsl:otherwise>
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
      
      -- Problems with responsibility for generating link tables:
      -- @entity = <xsl:value-of select="@entity"/>
      -- $nearside = <xsl:value-of select="$nearside"/>
      -- $farside = <xsl:value-of select="$farside"/>
      -- $farentity = <xsl:value-of select="count( $farentity/property)"/>
      -- farlink = <xsl:value-of select="$farentity/property[@type='link' and @entity=$nearside]/@name"/>
      -- comparison = '<xsl:value-of select="$comparison"/>'

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
            <xsl:value-of select="concat( 'ln_', $nearside, '_', @entity)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat( 'ln_', @entity, '_', $nearside)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      -- Responsibility = '<xsl:value-of select="$myresponsibility"/>'
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
          ALTER TABLE "<xsl:value-of select="$tablename"/>"
          ADD FOREIGN KEY ( "<xsl:value-of select="$nearside"/>Id")
          REFERENCES "<xsl:value-of select="$nearside"/>" ON DELETE NO ACTION

          GO

          ALTER TABLE "<xsl:value-of select="$tablename"/>"
          ADD FOREIGN KEY ( "<xsl:value-of select="$farside"/>Id")
          REFERENCES "<xsl:value-of select="$nearside"/>" ON DELETE NO ACTION

          GO

            </xsl:when>
            <xsl:otherwise>
          ALTER TABLE "<xsl:value-of select="$tablename"/>"
          ADD FOREIGN KEY ( "<xsl:value-of select="$nearside"/>Id")
          REFERENCES "<xsl:value-of select="$nearside"/>" ON DELETE CASCADE

          GO

          ALTER TABLE "<xsl:value-of select="$tablename"/>"
          ADD FOREIGN KEY ( "<xsl:value-of select="@entity"/>Id")
          REFERENCES "<xsl:value-of select="@entity"/>" ON DELETE CASCADE

          GO


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

  <xsl:template match="property[@type='list']">
          -- Suppressing output of property <xsl:value-of select="@name"/>, 
          -- as it is the 'one' end of a one-to-many relationship
  </xsl:template>
    
    <xsl:template match="property[@type='entity']">
            "<xsl:value-of select="@name"/>" INT<xsl:if 
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
                test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
    </xsl:template>

    <xsl:template match="property[@type='defined']">
        <xsl:variable name="name"><xsl:value-of select="@definition"/></xsl:variable>
        <xsl:variable name="definitiontype"><xsl:value-of select="/application/definition[@name=$name]/@type"/></xsl:variable>
            "<xsl:value-of select="@name"/>"<xsl:text> </xsl:text><xsl:choose>
            <xsl:when test="$definitiontype='string'">VARCHAR( <xsl:value-of 
                select="/application/definition[@name=$name]/@size"/>)</xsl:when>
            <xsl:when test="$definitiontype='integer'">INT</xsl:when>
            <xsl:when test="$definitiontype='real'">DOUBLE PRECISION</xsl:when>
            <xsl:otherwise><xsl:value-of select="$definitiontype"/></xsl:otherwise>
        </xsl:choose><xsl:if 
        test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
            test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
    </xsl:template>


    <xsl:template match="property[@type='boolean']">
            -- SQL Server doesn't have proper booleans!
            "<xsl:value-of select="@name"/>" BIT<xsl:choose>
              <xsl:when test="@default='true'"> DEFAULT 1</xsl:when>
              <xsl:when test="@default='false'"> DEFAULT 0</xsl:when>
            </xsl:choose><xsl:if test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
    </xsl:template>


    <xsl:template match="property[@type='string']">
            "<xsl:value-of select="@name"/>" VARCHAR( <xsl:value-of select="@size"/>)<xsl:if 
                test="string(@default)"> DEFAULT '<xsl:value-of select="@default"/>'</xsl:if><xsl:if 
                    test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
    </xsl:template>

    <xsl:template match="property[@type='date' or @type = 'time']">
            "<xsl:value-of select="@name"/>" DATETIME<xsl:if
                test="string(@default)"> DEFAULT <xsl:value-of select="@default"/>
              </xsl:if><xsl:if
                test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
    </xsl:template>


  <xsl:template match="property[@type='integer']">
            "<xsl:value-of select="@name"/>" INT<xsl:if 
                test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
                  test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
  </xsl:template>
    
  <xsl:template match="property[@type='real']">
            "<xsl:value-of select="@name"/>" DOUBLE PRECISION<xsl:if 
                test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
                    test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
  </xsl:template>
    
  <xsl:template match="property">
            "<xsl:value-of select="@name"/>" <xsl:text> </xsl:text><xsl:value-of select="@type"/><xsl:if 
                test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if 
                    test="@required='true'"> NOT NULL</xsl:if>,<xsl:text>
            </xsl:text>
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
