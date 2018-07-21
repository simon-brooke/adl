<?xml version="1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns="http://libs.cygnets.co.uk/adl/1.4/" 
  xmlns:adl="http://libs.cygnets.co.uk/adl/1.4/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
      Application Description Language framework
      adl2mssql.xsl
      
      (c) 2007 Cygnet Solutions Ltd
      
      Convert ADL to MS-SQL
      
      $Author: simon $
      $Revision: 1.21 $
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

	<!-- the convention to use for fieldnames in link tables:
		Name - the name of the foreign key is the same as the name of the table linked to
		NameId - the name of the foreign key is the same as the name of the table linked to, followed by 'Id'
		Name_Id - the name of the foreign key is the same as the name of the table linked to, followed by '_Id'
		Name_Link  - the name of the foreign key is the same as the name of the table linked to, followed by '_Link'
	-->
	<xsl:param name="linktable-field-name-convention" select="Name"/>
	
  <xsl:param name="database"/>
	<!-- the name and version of the product being built -->
	<xsl:param name="product-version" select="'Application Description Language Framework'"/>

	<!-- define upper and lower case letters to enable case conversion -->
  <xsl:variable name="ucase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
  <xsl:variable name="lcase">abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <!-- define SQL keywords to police these out of field names -->
  <xsl:variable name="sqlkeywords-multiline">
	  ADD 				EXCEPT 				PERCENT
	  ALL 				EXEC 				PLAN
	  ALTER 				EXECUTE				PRECISION
	  AND 				EXISTS 				PRIMARY
	  ANY 				EXIT 				PRINT
	  AS 					FETCH 				PROC
	  ASC 				FILE 				PROCEDURE
	  AUTHORIZATION 		FILLFACTOR 			PUBLIC
	  BACKUP 				FOR 				RAISERROR
	  BEGIN 				FOREIGN 			READ
	  BETWEEN 			FREETEXT 			READTEXT
	  BREAK 				FREETEXTTABLE 		RECONFIGURE
	  BROWSE 				FROM 				REFERENCES
	  BULK 				FULL 				REPLICATION
	  BY 					FUNCTION 			RESTORE
	  CASCADE 			GOTO 				RESTRICT
	  CASE 				GRANT 				RETURN
	  CHECK 				GROUP 				REVOKE
	  CHECKPOINT 			HAVING 				RIGHT
	  CLOSE 				HOLDLOCK		 	ROLLBACK
	  CLUSTERED 			IDENTITY		 	ROWCOUNT
	  COALESCE 			IDENTITY_INSERT 	ROWGUIDCOL
	  COLLATE 			IDENTITYCOL		 	RULE
	  COLUMN 				IF 					SAVE
	  COMMIT 				IN 					SCHEMA
	  COMPUTE 			INDEX			 	SELECT
	  CONSTRAINT 			INNER 				SESSION_USER
	  CONTAINS 			INSERT 				SET
	  CONTAINSTABLE 		INTERSECT		 	SETUSER
	  CONTINUE 			INTO 				SHUTDOWN
	  CONVERT 			IS 					SOME
	  CREATE 				JOIN			 	STATISTICS
	  CROSS 				KEY					SYSTEM_USER
	  CURRENT 			KILL			 	TABLE
	  CURRENT_DATE 		LEFT			 	TEXTSIZE
	  CURRENT_TIME 		LIKE			 	THEN
	  CURRENT_TIMESTAMP 	LINENO				TO
	  CURRENT_USER 		LOAD 				TOP
	  CURSOR 				NATIONAL 			TRAN
	  DATABASE 			NOCHECK 			TRANSACTION
	  DBCC 				NONCLUSTERED 		TRIGGER
	  DEALLOCATE 			NOT 				TRUNCATE
	  DECLARE 			NULL 				TSEQUAL
	  DEFAULT 			NULLIF 				UNION
	  DELETE 				OF 					UNIQUE
	  DENY 				OFF 				UPDATE
	  DESC 				OFFSETS				UPDATETEXT
	  DISK 				ON 					USE
	  DISTINCT	 		OPEN 				USER
	  DISTRIBUTED 		OPENDATASOURCE 		VALUES
	  DOUBLE 				OPENQUERY 			VARYING
	  DROP 				OPENROWSET 			VIEW
	  DUMMY 				OPENXML 			WAITFOR
	  DUMP 				OPTION 				WHEN
	  ELSE 				OR 					WHERE
	  END 				ORDER 				WHILE
	  ERRLVL 				OUTER				WITH
	  ESCAPE 				OVER				WRITETEXT
  </xsl:variable>
  <xsl:variable name="sqlkeywords" select="concat(' ', normalize-space($sqlkeywords-multiline), ' ')"/>


  <xsl:template match="adl:application"> 
        -------------------------------------------------------------------------------------------------
        --
        --    <xsl:value-of select="$product-version"/>
        --
        --    Database for application <xsl:value-of select="@name"/> version <xsl:value-of select="@version"/>
        --    Generated for MS-SQL 2000+ using adl2mssql.xslt <xsl:value-of select="substring('$Revision: 1.21 $', 12)"/>
	    --    THIS FILE IS AUTOMATICALLY GENERATED: DO NOT EDIT IT.
		--
		--    <xsl:value-of select="@revision"/>
        --
        --    Code generator (c) 2007 Cygnet Solutions Ltd
        --
        -------------------------------------------------------------------------------------------------

    <xsl:if test="string-length( $database) &gt; 0">
      use "<xsl:value-of select="$database"/>";
    </xsl:if>

        -------------------------------------------------------------------------------------------------
        --    authentication roles
        -------------------------------------------------------------------------------------------------
    <xsl:apply-templates select="adl:group"/>

	  -------------------------------------------------------------------------------------------------
	  --	magic view for role membership, used in establishing security credentials
	  -------------------------------------------------------------------------------------------------
	  CREATE VIEW RoleMembership AS
		 SELECT dbuser.name as "dbuser", 
				dbrole.name as "dbrole"
		   FROM sysusers AS dbuser, sysmembers, sysusers AS dbrole
		  WHERE dbuser.uid = sysmembers.memberuid
			AND dbrole.uid = sysmembers.groupuid
	  GO
			
	  GRANT SELECT on RoleMembership to public
	  GO

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
    <xsl:apply-templates select="adl:entity" mode="refinteg"/>
      
        -------------------------------------------------------------------------------------------------
        --    end of file
        -------------------------------------------------------------------------------------------------
  </xsl:template>

	<xsl:template match="adl:documentation">
		/*    <xsl:apply-templates/> */
	</xsl:template>
	
  <xsl:template match="adl:group">
		-------------------------------------------------------------------------------------------------
		--    security group <xsl:value-of select="@name"/>
		-------------------------------------------------------------------------------------------------
	  <xsl:apply-templates select="adl:documentation"/>
		execute sp_addrole @rolename = '<xsl:value-of select="@name"/>'
		GO
  </xsl:template>

  <!-- return the table name for the entity with this entity name -->
  <xsl:template name="tablename">
    <xsl:param name="entityname"/>
    <xsl:choose>
      <xsl:when test="//adl:entity[@name=$entityname]/@table">
        <xsl:value-of select="//adl:entity[@name=$entityname]/@table"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$entityname"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- generate a foreign key referential integrity check -->
  <xsl:template name="foreignkey">
    <xsl:param name="nearside"/>
    <xsl:param name="farside"/>
    <xsl:param name="linkfield"/>
    <xsl:param name="ondelete" select="'NO ACTION'"/>

    <xsl:variable name="neartable">
      <xsl:call-template name="tablename">
        <xsl:with-param name="entityname" select="$nearside"/>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="fartable">
      <xsl:call-template name="tablename">
        <xsl:with-param name="entityname" select="$farside"/>
      </xsl:call-template>
    </xsl:variable>
    
    <!-- set up referential integrity constraints for primary tables -->
        ALTER TABLE "<xsl:value-of select="$neartable"/>"
            ADD FOREIGN KEY ( "<xsl:value-of select="$linkfield"/>") 
            REFERENCES "<xsl:value-of select="$fartable"/>" ON DELETE <xsl:value-of select="$ondelete"/>
            
        GO
  </xsl:template>

  <!-- generate referential integrity constraints -->
  <!-- there's a sort-of problem with this - if we have properties at both 
	ends of a link (which we often do) we currently generate two identical 
	constraints. This doesn't seem to cause any major problems but must hurt 
	efficiency. It would be better if we fixed this. -->
  <xsl:template match="adl:entity" mode="refinteg">
    <xsl:variable name="nearside" select="@name"/>
    <xsl:for-each select="descendant::adl:property[@type='entity']">
      <xsl:variable name="farside" select="@entity"/>
      <xsl:variable name="keyfield">
        <xsl:call-template name="property-column-name">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="//adl:entity[@name=$farside]//adl:property[@farkey=$keyfield and @entity=$nearside]">
          <!-- there's a 'list' property pointing the other way; let it do the heavy hauling -->
			<!-- list with farkey -->
        </xsl:when>
		  <xsl:when test="//adl:entity[@name=$farside]//adl:property[@entity=$nearside and not( @farkey)]">
			  <!-- there's a 'list' property pointing the other way; let it do the heavy hauling -->
			  <!-- list with no farkey -->
		  </xsl:when>
		  <xsl:otherwise>
          <xsl:call-template name="foreignkey">
            <xsl:with-param name="nearside" select="$nearside"/>
            <xsl:with-param name="farside" select="$farside"/>
            <xsl:with-param name="linkfield" select="$keyfield"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="descendant::adl:property[@type='list']">
		<xsl:variable name="ns2" select="@entity"/>
		<xsl:variable name="linkfield">
			<xsl:call-template name="property-column-name">
				<xsl:with-param name="property" 
								select="//adl:entity[@name=$ns2]//adl:property[@entity=$nearside]"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="string-length( $linkfield) = 0">
			<xsl:message terminate="yes">
				ADL: ERROR: Failed to infer link field name whilst processing list property <xsl:value-of select="@name"/> of <xsl:value-of select="ancestor::adl:entity/@name"/>
 Entity is '<xsl:value-of select="$ns2"/>', nearside is '<xsl:value-of select="$nearside"/>'
			</xsl:message>
		</xsl:if>
      <xsl:call-template name="foreignkey">
        <xsl:with-param name="nearside" select="@entity"/>
        <xsl:with-param name="farside" select="../@name"/>
        <xsl:with-param name="linkfield" select="$linkfield"/>
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
  </xsl:template>
  
  
  <!-- don't generate foreign tables - although we will generate ref integ constraints for them -->
  <xsl:template match="adl:entity[@foreign='true']" mode="table"/> 

  <xsl:template match="adl:entity" mode="table">
	  <!-- the name of the entity we're generating -->
	  <xsl:variable name="entityname" select="@name"/>
	  <!-- the name of the table to generate -->
	  <xsl:variable name="table">
		  <xsl:call-template name="tablename">
			  <xsl:with-param name="entityname" select="@name"/>
		  </xsl:call-template>
	  </xsl:variable>
	  <!-- the entity we are generating -->
	  <xsl:variable name="generating-entity" select="."/>

		-------------------------------------------------------------------------------------------------
		--    primary table <xsl:value-of select="$table"/>
        -------------------------------------------------------------------------------------------------
 	  <xsl:apply-templates select="adl:documentation"/>
		CREATE TABLE  "<xsl:value-of select="$table"/>"
		(
	  <xsl:for-each select="descendant::adl:property[not( @type='link' or @type = 'list' or @concrete='false')]">
		  <xsl:apply-templates select="."/>
		  <xsl:if test="position() != last()">,</xsl:if>
	  </xsl:for-each>
	  <xsl:for-each select="//adl:property[@type='list' and @entity = $entityname]">
		  <xsl:variable name="referringprop" select="."/>
		  <xsl:choose>
			  <xsl:when test="$generating-entity//adl:property[ @type='entity' and @entity=$referringprop/ancestor::adl:entity/@name]">
				  <!-- if the entity for which I'm currently generating already has a specified property
				  which links to this foreign entity, I don't have to dummy one up -->
			  </xsl:when>
			  <xsl:otherwise>
				  <!-- dummy up the 'many' end of a one-to-many link -->
				  , "<xsl:value-of select="ancestor::adl:entity/@name"/>"<xsl:text> </xsl:text><xsl:call-template name="sql-type">
					  <xsl:with-param name="property" select="ancestor::adl:entity/adl:key/adl:property[position() = 1]"/>
				  </xsl:call-template>
			  </xsl:otherwise>
		  </xsl:choose>
	  </xsl:for-each>
    <xsl:apply-templates select="adl:key"/>
        )
        GO

        ----  permissions  ------------------------------------------------------------------------------
    <xsl:for-each select="adl:permission">
      <xsl:call-template name="permission">
        <xsl:with-param name="entity" select="ancestor::adl:entity"/>
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

  <xsl:template match="adl:key">
    <xsl:if test="adl:property[not( @concrete='false')]">
          , 
          PRIMARY KEY( <xsl:for-each select="adl:property[not( @concrete='false')]">"<xsl:call-template name="property-column-name">
            <xsl:with-param name="property" select="."/>
          </xsl:call-template>"<xsl:if test="position() != last()">, </xsl:if></xsl:for-each>)
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
    <xsl:variable name="entityname" select="@name"/>
    <xsl:for-each select="adl:property[@type='link']">
      <xsl:call-template name="linktable">
        <xsl:with-param name="nearside" select="$entityname"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="permission">
    <xsl:param name="entity"/>
    <!-- decode the permissions for a table -->
    <xsl:variable name="table">
      <xsl:call-template name="tablename">
        <xsl:with-param name="entityname" select="$entity/@name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="@permission='read'">
        GRANT SELECT ON "<xsl:value-of
                select="$table"/>" TO "<xsl:value-of select="@group"/>"
      </xsl:when>
      <xsl:when test="@permission='insert'">
        GRANT INSERT ON "<xsl:value-of
                select="$table"/>" TO "<xsl:value-of select="@group"/>"
      </xsl:when>
      <xsl:when test="@permission='noedit'">
        GRANT SELECT, INSERT ON "<xsl:value-of
                select="$table"/>" TO "<xsl:value-of select="@group"/>"
      </xsl:when>
      <xsl:when test="@permission='edit'">
        GRANT SELECT, INSERT, UPDATE ON "<xsl:value-of
                select="$table"/>" TO "<xsl:value-of select="@group"/>"
      </xsl:when>
      <xsl:when test="@permission='all'">
        GRANT SELECT, INSERT, UPDATE, DELETE ON "<xsl:value-of
                select="$table"/>" TO "<xsl:value-of select="@group"/>"
      </xsl:when>
      <xsl:otherwise>
        REVOKE ALL ON "<xsl:value-of
                select="$table"/>" FROM "<xsl:value-of select="@group"/>"
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>
        GO
        
    </xsl:text>
  </xsl:template>

  <!-- expects to be called in the context of an entity; probably should make this explicit. 
    TODO: this is a mess; refactor. -->
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
      <xsl:variable name="farentityname" select="@entity"/>
      <xsl:variable name="farentity" select="//adl:entity[@name=$farentityname]"/>
	  <xsl:variable name="linksuffix">
		  <xsl:choose>
			  <xsl:when test="$linktable-field-name-convention = 'Name'"/>
			  <xsl:when test="$linktable-field-name-convention = 'NameId'">
				  <xsl:value-of select="'Id'"/>
			  </xsl:when>
			  <xsl:when test="$linktable-field-name-convention = 'Name_Id'">
				  <xsl:value-of select="'_Id'"/>
			  </xsl:when>
			  <xsl:when test="$linktable-field-name-convention = 'NameLink'">
				  <xsl:value-of select="'Link'"/>
			  </xsl:when>
			  <xsl:when test="$linktable-field-name-convention = 'Name_Link'">
				  <xsl:value-of select="'_Link'"/>
			  </xsl:when>
		  </xsl:choose>
	  </xsl:variable>

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
              <xsl:when test="$farentity/adl:property[@type='link' and @entity=$nearside]">false</xsl:when>
              <xsl:otherwise>true</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- Problems with responsibility for generating link tables: -->
        -- Problems with responsibility for generating link tables:
        -- @entity = <xsl:value-of select="@entity"/>
        -- $nearside = <xsl:value-of select="$nearside"/>
        -- $farside = <xsl:value-of select="$farside"/>
        -- farlink = <xsl:value-of select="$farentity/adl:property[@type='link' and @entity=$nearside]/@name"/>
        -- comparison = '<xsl:value-of select="$comparison"/>' 
        -- my responsibility = <xsl:value-of select="$myresponsibility"/>
      <xsl:variable name="linktablename">
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
        CREATE TABLE "<xsl:value-of select="$linktablename"/>"
        (
          "<xsl:value-of select="concat( $nearside, $linksuffix)"/>" <xsl:call-template name="sql-type">
            <xsl:with-param name="property" select="//adl:entity[@name=$nearside]/adl:key/adl:property[position()=1]"/>
          </xsl:call-template> NOT NULL,
          "<xsl:value-of select="concat( $farside, $linksuffix)"/>" <xsl:call-template name="sql-type">
          <xsl:with-param name="property" select="$farentity/adl:key/adl:property[position()=1]"/>
          </xsl:call-template> NOT NULL
        )

        GO
          <xsl:text>
            
          </xsl:text>
        ----  permissions  ------------------------------------------------------------------------------
        <!-- only two levels of permission really matter for a link table. If you can read both of the 
        parent tables, then you can read the link table. If you can edit either of the parent tables, 
        then you need full CRUD permissions on the link table. Otherwise, you get nothing. -->
        <xsl:for-each select="//adl:group">
          <xsl:variable name="groupname" select="@name"/>
            <xsl:choose>
              <xsl:when test="//adl:entity[@name=$nearside]/adl:permission[@group=$groupname and @permission='all']">
        GRANT SELECT,INSERT,UPDATE,DELETE ON "<xsl:value-of select="$linktablename"/>" TO "<xsl:value-of select="$groupname"/>" 
              </xsl:when>
              <xsl:when test="//adl:entity[@name=$nearside]/adl:permission[@group=$groupname and @permission='edit']">
		GRANT SELECT,INSERT,UPDATE,DELETE ON "<xsl:value-of select="$linktablename"/>" TO "<xsl:value-of select="$groupname"/>"
			  </xsl:when>
              <xsl:when test="//adl:entity[@name=$farside]/adl:permission[@group=$groupname and @permission='all']">
		GRANT SELECT,INSERT,UPDATE,DELETE ON "<xsl:value-of select="$linktablename"/>" TO "<xsl:value-of select="$groupname"/>"
			  </xsl:when>
              <xsl:when test="//adl:entity[@name=$farside]/adl:permission[@group=$groupname and @permission='edit']">
		GRANT SELECT,INSERT,UPDATE,DELETE ON "<xsl:value-of select="$linktablename"/>" TO "<xsl:value-of select="$groupname"/>"
			  </xsl:when>
              <xsl:when test="//adl:entity[@name=$nearside]/adl:permission[@group=$groupname and @permission='none']">
		REVOKE ALL ON "<xsl:value-of select="$linktablename"/>" FROM "<xsl:value-of select="$groupname"/>"
			  </xsl:when>
              <xsl:when test="//adl:entity[@name=$farside]/adl:permission[@group=$groupname and @permission='none']">
		REVOKE ALL ON "<xsl:value-of select="$linktablename"/>" FROM "<xsl:value-of select="$groupname"/>"
			  </xsl:when>
              <xsl:otherwise>
        GRANT SELECT ON <xsl:value-of select="$linktablename"/> TO <xsl:value-of select="$groupname"/>
              </xsl:otherwise>
            </xsl:choose>
        GO
          </xsl:for-each>
          
        ----  referential integrity  --------------------------------------------------------------------
        
          <xsl:variable name="neartable">
            <xsl:call-template name="tablename">
              <xsl:with-param name="entityname" select="$nearside"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="fartable">
            <xsl:call-template name="tablename">
              <xsl:with-param name="entityname" select="$farentityname"/>
            </xsl:call-template>
          </xsl:variable>

          <xsl:choose>
            <xsl:when test="$nearside=@entity">
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$linktablename"/>
                <xsl:with-param name="farside" select="$neartable"/>
                <xsl:with-param name="linkfield" select="concat( $nearside, $linksuffix)"/>
                <xsl:with-param name="ondelete" select="'NO ACTION'"/>
              </xsl:call-template>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$linktablename"/>
                <xsl:with-param name="farside" select="$fartable"/>
                <xsl:with-param name="linkfield" select="concat( $farside, $linksuffix)"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$linktablename"/>
                <xsl:with-param name="farside" select="$neartable"/>
                <xsl:with-param name="linkfield" select="concat( $nearside, $linksuffix)"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
              <xsl:call-template name="foreignkey">
                <xsl:with-param name="nearside" select="$linktablename"/>
                <xsl:with-param name="farside" select="$fartable"/>
                <xsl:with-param name="linkfield" select="concat( @entity, $linksuffix)"/>
                <xsl:with-param name="ondelete" select="'CASCADE'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
        -- Suppressing generation of <xsl:value-of select="$linktablename"/>, as it is not my responsibility
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="myresponsibility='true'">
      </xsl:if>
    </xsl:template>
  
  <xsl:template match="adl:property[@type='list']">
        -- Suppressing output of property <xsl:value-of select="@name"/>,
        -- as it is the 'one' end of a one-to-many relationship
  </xsl:template>

  <xsl:template match="adl:generator[@action='native']">
    IDENTITY( 1, 1)
  </xsl:template>
  <xsl:template match="adl:generator"/>

  <!-- the grand unified property handler, using the sql-type template to 
  generate the correct types for each field -->
  <xsl:template match="adl:property">
    <xsl:variable name="column">
      <xsl:call-template name="property-column-name">
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
				<xsl:when test="$base-type = 'boolean'">
					<xsl:choose>
						<xsl:when test="@default='true'">1</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
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
      <xsl:call-template name="property-column-name">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="type">
      <xsl:call-template name="sql-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="entity" select="@entity"/>
    <xsl:variable name="defaulttype">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" 
                        select="ancestor::adl:application/adl:entity[@name = $entity]/adl:key/adl:property[position() = 1]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="default">
      <xsl:choose>
        <xsl:when test="$defaulttype = 'string'">
          '<xsl:value-of select="@default"/>'
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@default"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
          "<xsl:value-of select="$column"/>" <xsl:value-of select="$type"/><xsl:if 
            test="string(@default)"> DEFAULT <xsl:value-of select="normalize-space($default)"/></xsl:if><xsl:if 
                test="@required='true'"> NOT NULL</xsl:if>
  </xsl:template>


  <!-- consistent, repeatable way of getting the column name for a given property -->
  <xsl:template name="property-column-name">
    <!-- a property element -->
    <xsl:param name="property"/>
    <xsl:variable name="unescaped">
    <xsl:choose>
      <xsl:when test="$property/@column">
        <xsl:value-of select="$property/@column"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$property/@name"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="contains( $sqlkeywords, concat(' ', translate( $unescaped, $lcase, $ucase),' '))">
		  <!--
			names which are keywords need to be escaped /either/ with square
			brackets /or/ with quotes, but currently we're using quotes for all names
			so don't need square brackets.
			xsl:value-of select="concat( '[', $unescaped, ']')"/ -->
		  <xsl:value-of select="$unescaped"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$unescaped"/>
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
                  entity '<xsl:value-of select="$property/@entity"/>', but this entity has no key.
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
      <xsl:when test="$base-type = 'image'">VARCHAR( <xsl:value-of select="$base-size"/>)</xsl:when>
      <xsl:when test="$base-type = 'text'">TEXT</xsl:when>
      <xsl:when test="$base-type = 'boolean'">BIT</xsl:when>
      <xsl:when test="$base-type = 'timestamp'">DATETIME</xsl:when>
      <xsl:when test="$base-type = 'integer'">INT</xsl:when>
      <xsl:when test="$base-type = 'real'">DOUBLE PRECISION</xsl:when>
      <xsl:when test="$base-type = 'money'">DECIMAL( 16, 2)</xsl:when>
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