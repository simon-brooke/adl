<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns="http://bowyer.journeyman.cc/adl/1.4.1/"
  xmlns:adl="http://bowyer.journeyman.cc/adl/1.4.1/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!--  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  -->
    <!--						    											-->
    <!--	adl2psql.xsl			    										-->
    <!--																		-->
    <!--	Purpose:															-->
    <!--	XSL stylesheet to generate Postgresql [7|8] from ADL.				-->
    <!--																		-->
    <!--	Author:		Simon Brooke <simon@weft.co.uk>							-->
    <!--	Created:	24th January 2006										-->
    <!--	Copyright:	(c) 2006 Simon Brooke.									-->
    <!--      							      									-->
    <!--	This file is presently not up to date with changes in ADL   -->
    <!--																		-->
    <!--  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  -->

    <!--
        JACQUARD 2 APPLICATION DESCRIPTION LANGUAGE FRAMEWORK

        $Revision: 1.3 $

        NOTES:

        Needless to say this is all hugely experimental.

        Running the primary key field last is a hack which gets around the fact that
        otherwise it's extremely complex to lose the comma after the last field.
        Ideally where there is one 'distinct="system"' property of an entity that
        should be the primary key and perhaps we'll achieve that in the long run...

        Still to do:

        References in convenience views for fields which have their reference value at
        two removes (i.e. the 'distinguish' mechanism in ADL
    -->

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
        --    Generated for PostgreSQL [7|8] using adl2psql.xsl $Revision: 1.3 $
        --
		--    <xsl:value-of select="@revision"/>
 		--
        --    Code generator (c) 2006 Simon Brooke [simon@weft.co.uk]
        --    http://www.weft.co.uk/library/jacquard/
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
        --    tables, views and permissions
        -------------------------------------------------------------------------------------------------
        <xsl:apply-templates select="adl:entity"/>

        -------------------------------------------------------------------------------------------------
        --    referential integrity constraints
        -------------------------------------------------------------------------------------------------
        <xsl:for-each select="adl:entity">
            <xsl:variable name="nearside" select="@name"/>
            <xsl:for-each select="adl:property[@type='entity']">
                <xsl:call-template name="referentialintegrity">
                    <xsl:with-param name="nearside" select="$nearside"/>
                </xsl:call-template>

            </xsl:for-each>
            <xsl:for-each select="adl:property[@type='link']">
                <xsl:call-template name="linkintegrity">
                    <xsl:with-param name="nearside" select="$nearside"/>
                </xsl:call-template>

            </xsl:for-each>
        </xsl:for-each>
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
        CREATE GROUP <xsl:value-of select="@name"/>;
    </xsl:template>


    <xsl:template name="referentialintegrity">
        <xsl:param name="nearside"/>
        <!-- set up referential integrity constraints for primary tables -->
        ALTER TABLE <xsl:value-of select="$nearside"/> ADD CONSTRAINT ri_<xsl:value-of select="$nearside"/><xsl:value-of select="concat( '_', @name)"/>
            FOREIGN KEY ( <xsl:value-of select="@name"/>) REFERENCES <xsl:value-of select="@entity"/> ON DELETE NO ACTION;
    </xsl:template>


    <xsl:template name="linkintegrity">
        <xsl:param name="nearside"/>
        <!-- set up referential integrity constraints for link tables -->
        ALTER TABLE ln_<xsl:value-of select="$nearside"/>_<xsl:value-of select="@entity"/>
            ADD CONSTRAINT ri_<xsl:value-of select="$nearside"/>_<xsl:value-of select="@entity"/>_<xsl:value-of select="$nearside"/>_id
            FOREIGN KEY ( <xsl:value-of select="$nearside"/>_id) REFERENCES <xsl:value-of select="$nearside"/> ON DELETE CASCADE;

        ALTER TABLE ln_<xsl:value-of select="$nearside"/>_<xsl:value-of select="@entity"/>
            ADD CONSTRAINT ri_<xsl:value-of select="$nearside"/>_<xsl:value-of select="@entity"/>_<xsl:value-of select="@entity"/>_id
            FOREIGN KEY ( <xsl:value-of select="@entity"/>_id) REFERENCES <xsl:value-of select="@entity"/> ON DELETE CASCADE;

    </xsl:template>


    <xsl:template match="adl:entity">
         <xsl:variable name="table" select="@name"/>

        -------------------------------------------------------------------------------------------------
        --    primary table <xsl:value-of select="@name"/>
        -------------------------------------------------------------------------------------------------
        CREATE TABLE  <xsl:value-of select="@name"/>
        (
        	<xsl:for-each select="descendant::adl:property[@type!='link']">
        		<xsl:apply-templates select="."/><xsl:choose>
        			<xsl:when test="position() = last()"/>
        			<xsl:otherwise>,<xsl:text>
        			</xsl:text></xsl:otherwise>
        		</xsl:choose>
        	</xsl:for-each>
        );

        ----  permissions  ------------------------------------------------------------------------------
        <xsl:for-each select="adl:permission">
            <xsl:call-template name="permission">
                <xsl:with-param name="table" select="$table"/>
            </xsl:call-template>
        </xsl:for-each>
        -------------------------------------------------------------------------------------------------
        --    convenience view lv<xsl:value-of select="concat( '_', @name)"/> for lists
        -------------------------------------------------------------------------------------------------
        CREATE VIEW lv<xsl:value-of select="concat( '_', @name)"/> AS
        SELECT <xsl:for-each select="adl:property[@type!='link']">
            <xsl:choose>
               <xsl:when test="@type='entity'">
                   <xsl:call-template name="distinctfield">
                       <xsl:with-param name="table" select="@entity"/>
                       <xsl:with-param name="alias" select="@name"/>
                   </xsl:call-template> AS <xsl:value-of select="@name"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="$table"/>.<xsl:value-of select="@name"/>
                </xsl:otherwise>
            </xsl:choose><xsl:choose>
                <xsl:when test="position() = last()"></xsl:when>
                <xsl:otherwise>,
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        FROM  <xsl:value-of select="@name"/>
        <xsl:for-each select="adl:property[@type='entity']">, <xsl:value-of select="@entity"/> AS <xsl:value-of select="@name"/></xsl:for-each>
        <xsl:text>
        </xsl:text>
        <xsl:for-each select="adl:property[@type='entity']">
            <xsl:choose>
            <xsl:when test="position() = 1">WHERE </xsl:when>
            <xsl:otherwise>AND   </xsl:otherwise>
            </xsl:choose><xsl:value-of select="$table"/>.<xsl:value-of
                select="@name"/> = <xsl:value-of select="@name"/>.<xsl:value-of select="@entity"/>_id
        </xsl:for-each>;

        ----  permissions  ------------------------------------------------------------------------------
        <xsl:for-each select="adl:permission">
            <xsl:call-template name="viewpermission">
                <xsl:with-param name="table" select="$table"/>
            </xsl:call-template>
        </xsl:for-each>

        <!-- link tables -->
        <xsl:for-each select="adl:property[@type='link']">
            <xsl:call-template name="linktable">
                <xsl:with-param name="nearside" select="$table"/>
            </xsl:call-template>
        ----  permissions  ------------------------------------------------------------------------------
            <xsl:variable name="farside" select="@entity"/>
            <xsl:for-each select="../permission">
            <xsl:call-template name="permission">
                    <xsl:with-param name="table">ln_<xsl:value-of select="$table"/>_<xsl:value-of select="$farside"/></xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>

    </xsl:template>

    <xsl:template name="distinctfield">
        <xsl:param name="table"/>
        <xsl:param name="alias"/>
        <!--
            print the names of the distinguishing fields in this table,
            concatenating into a single string.
        -->
        Template distinctfield entered, table is <xsl:value-of select="$table"/>.
            <xsl:for-each select="//entity[@name=$table]/property[@distinct='user' or @distinct='all']">
                <xsl:choose>
                    <xsl:when test="@type='entity'">
                    Entity <xsl:value-of select="@name"/> detected.
                        <xsl:call-template name="distinctfield">
                            <xsl:with-param name="table" select="@entity"/>
                            <xsl:with-param name="alias" select="concat( $alias, '_', @name)"></xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$alias"/>.<xsl:value-of
                        select="@name"/><xsl:if test="position() != last()"> | ', ' | </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>
    </xsl:template>

    <xsl:template name="permission">
        <xsl:param name="table"/>
        <!-- decode the permissions for a table -->
        <xsl:choose>
            <xsl:when test="@permission='read'">GRANT SELECT ON <xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:when test="@permission='insert'">GRANT INSERT ON <xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:when test="@permission='noedit'">GRANT SELECT, INSERT ON <xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:when test="@permission='edit'">GRANT SELECT, INSERT, UPDATE ON <xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:when test="@permission='all'">GRANT SELECT, INSERT, UPDATE, DELETE ON <xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:otherwise>REVOKE ALL ON <xsl:value-of
                select="$table"/> FROM GROUP <xsl:value-of select="@group"/>;</xsl:otherwise>
        </xsl:choose>
        <xsl:text>

        </xsl:text>
    </xsl:template>

    <xsl:template name="viewpermission">
        <xsl:param name="table"/>
        <!-- decode the permissions for a convenience view -->
        <xsl:choose>
            <xsl:when test="@permission='none'">REVOKE ALL ON lv_<xsl:value-of
                select="$table"/> FROM GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:when test="@permission='insert'">REVOKE ALL ON lv_<xsl:value-of
                select="$table"/> FROM GROUP <xsl:value-of select="@group"/>;</xsl:when>
            <xsl:otherwise>GRANT SELECT ON lv_<xsl:value-of
                select="$table"/> TO GROUP <xsl:value-of select="@group"/>;</xsl:otherwise>
        </xsl:choose>
        <xsl:text>

        </xsl:text>
    </xsl:template>


    <xsl:template name="linktable">
        <xsl:param name="nearside"/>
      <xsl:variable name="farside">
        <xsl:choose>
          <xsl:when test="@entity = $nearside"><xsl:value-of select="@entity"/>_1</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@entity"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- create a linking table -->

        -------------------------------------------------------------------------------------------------
        --    link table joining <xsl:value-of select="$nearside"/> with <xsl:value-of select="@entity"/>
        -------------------------------------------------------------------------------------------------
        CREATE TABLE ln_<xsl:value-of select="$nearside"/>_<xsl:value-of select="@entity"/>
        (
            <xsl:value-of select="$nearside"/>_id INT NOT NULL,
            <xsl:value-of select="$farside"/>_id INT NOT NULL,
        );
        <xsl:text>

        </xsl:text>
        <!-- TODO: permissions for link tables! -->

    </xsl:template>

    <xsl:template match="adl:property[@type='entity']">
        <xsl:value-of select="@name"/> INT<xsl:if
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if
                test="@required='true'"> NOT NULL</xsl:if>
    </xsl:template>

    <xsl:template match="adl:property[@type='defined']">
        <xsl:variable name="name"><xsl:value-of select="@definition"/></xsl:variable>
        <xsl:variable name="definitiontype"><xsl:value-of select="/application/definition[@name=$name]/@type"/></xsl:variable>
        <xsl:value-of select="@name"/><xsl:text> </xsl:text><xsl:choose>
            <xsl:when test="$definitiontype='string'">VARCHAR( <xsl:value-of
                select="/application/definition[@name=$name]/@size"/>)</xsl:when>
            <xsl:when test="$definitiontype='integer'">INT</xsl:when>
            <xsl:when test="$definitiontype='real'">DOUBLE PRECISION</xsl:when>
            <xsl:otherwise><xsl:value-of select="$definitiontype"/></xsl:otherwise>
        </xsl:choose><xsl:if
        test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:choose>
			<xsl:when test="parent::adl:key"> NOT NULL PRIMARY KEY</xsl:when>
			<xsl:when test="@required='true'"> NOT NULL</xsl:when>
		</xsl:choose>
    </xsl:template>

    <xsl:template match="adl:property[@type='string']">
        <xsl:value-of select="@name"/> VARCHAR( <xsl:value-of select="@size"/>)<xsl:if
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:choose>
			<xsl:when test="parent::adl:key"> NOT NULL PRIMARY KEY</xsl:when>
			<xsl:when test="@required='true'"> NOT NULL</xsl:when>
		</xsl:choose>
    </xsl:template>

    <xsl:template match="adl:property[@type='integer']">
        <xsl:value-of select="@name"/> INT<xsl:if
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:choose>
			<xsl:when test="parent::adl:key"> NOT NULL PRIMARY KEY</xsl:when>
			<xsl:when test="@required='true'"> NOT NULL</xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="adl:property[@type='real']">
        <xsl:value-of select="@name"/> DOUBLE PRECISION<xsl:if
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:if
                test="@required='true'"> NOT NULL</xsl:if>
    </xsl:template>

    <xsl:template match="adl:property">
        <xsl:value-of select="@name"/> <xsl:text> </xsl:text><xsl:value-of select="@type"/><xsl:if
            test="string(@default)"> DEFAULT <xsl:value-of select="@default"/></xsl:if><xsl:choose>
			<xsl:when test="parent::adl:key"> NOT NULL PRIMARY KEY</xsl:when>
			<xsl:when test="@required='true'"> NOT NULL</xsl:when>
		</xsl:choose>
    </xsl:template>

</xsl:stylesheet>
