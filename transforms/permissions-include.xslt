<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
	xmlns="http://libs.cygnets.co.uk/adl/1.1/"
	xmlns:adl="http://libs.cygnets.co.uk/adl/1.1/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
				xmlns:exsl="urn:schemas-microsoft-com:xslt"
                extension-element-prefixes="exsl">
	<!--
    Application Description Language framework
    permissions-include.xslt
    
    (c) 2007 Cygnet Solutions Ltd
    
    Utility templates to find permissions on various things
    
    $Author: sb $
    $Revision: 1.1 $
    $Date: 2009-02-06 12:08:28 $
	-->

	<!-- collect all groups which can edit the specified property -->
	<xsl:template name="property-edit-groups">
		<xsl:param name="property"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="perm">
				<xsl:call-template name="property-permission">
					<xsl:with-param name="property" select="$property"/>
					<xsl:with-param name="groupname" select="@name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='edit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- those groups which can insert -->
	<xsl:template name="property-insert-groups">
		<xsl:param name="property"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="perm">
				<xsl:call-template name="property-permission">
					<xsl:with-param name="property" select="$property"/>
					<xsl:with-param name="groupname" select="@name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='edit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='insert'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='noedit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- those groups which can read -->
	<xsl:template name="property-read-groups">
		<xsl:param name="property"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="perm">
				<xsl:call-template name="property-permission">
					<xsl:with-param name="property" select="$property"/>
					<xsl:with-param name="groupname" select="@name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='edit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='insert'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='noedit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='read'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- collect the groups which can read an entity -->
	<xsl:template name="entity-read-groups">
		<xsl:param name="entity"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="groupname" select="@name"/>
			<xsl:variable name="perm">
				<xsl:choose>
					<xsl:when test="$entity/adl:permission[@group=$groupname]">
						<xsl:value-of select="$entity/adl:permission[@group=$groupname]/@permission"/>
					</xsl:when>
					<xsl:otherwise>none</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='edit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='insert'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='noedit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='read'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- collect the groups which can delete an entity -->
	<xsl:template name="entity-delete-groups">
		<xsl:param name="entity"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="groupname" select="@name"/>
			<xsl:variable name="perm">
				<xsl:choose>
					<xsl:when test="$entity/adl:permission[@group=$groupname]">
						<xsl:value-of select="$entity/adl:permission[@group=$groupname]/@permission"/>
					</xsl:when>
					<xsl:otherwise>none</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>


	<!-- collect the groups which can read a page, form or list -->
	<xsl:template name="page-read-groups">
		<xsl:param name="page"/>
		<xsl:for-each select="//adl:group">
			<xsl:variable name="perm">
				<xsl:call-template name="page-permission">
					<xsl:with-param name="page" select="$page"/>
					<xsl:with-param name="groupname" select="@name"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$perm='all'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='edit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='insert'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='noedit'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:when test="$perm='read'">
					<xsl:copy-of select="."/>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- find, as a string, the permission which applies to this property in the context of the named group.
      NOTE: recurses up the group hierarchy - if it has cycles that's your problem, buster.
      page: a page, list or form element
      groupname: a string, being the name of a group
    -->
	<xsl:template name="page-permission">
		<xsl:param name="page"/>
		<xsl:param name="groupname" select="'public'"/>
		<xsl:choose>
			<xsl:when test="$page/adl:permission[@group=$groupname]">
				<xsl:value-of select="$page/adl:permission[@group=$groupname]/@permission"/>
			</xsl:when>
			<xsl:when test="$page/ancestor::adl:entity/adl:permission[@group=$groupname]">
				<xsl:value-of select="$page/ancestor::adl:entity/adl:permission[@group=$groupname]/@permission"/>
			</xsl:when>
			<xsl:when test="//adl:group[@name=$groupname]/@parent">
				<xsl:call-template name="page-permission">
					<xsl:with-param name="page" select="$page"/>
					<xsl:with-param name="groupname" select="//adl:group[@name=$groupname]/@parent"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>none</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- find, as a string, the permission which applies to this property in the context of the named group.
      NOTE: recurses up the group hierarchy - if it has cycles that's your problem, buster.
      property: a property element
      groupname: a string, being the name of a group
    -->
	<xsl:template name="property-permission">
		<xsl:param name="property"/>
		<xsl:param name="groupname" select="'public'"/>
		<xsl:choose>
			<xsl:when test="$property/adl:permission[@group=$groupname]">
				<xsl:value-of select="$property/adl:permission[@group=$groupname]/@permission"/>
			</xsl:when>
			<xsl:when test="$property/ancestor::adl:entity/adl:permission[@group=$groupname]">
				<xsl:value-of select="$property/ancestor::adl:entity/adl:permission[@group=$groupname]/@permission"/>
			</xsl:when>
			<xsl:when test="//adl:group[@name=$groupname]/@parent">
				<xsl:call-template name="property-permission">
					<xsl:with-param name="property" select="$property"/>
					<xsl:with-param name="groupname" select="//adl:group[@name=$groupname]/@parent"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>none</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- find, as a string, the permission which applies to this field in the context of the named group
      field: a field element
      groupname: a string, being the name of a group
    -->
    <xsl:template name="field-permission">
      <xsl:param name="field"/>
      <xsl:param name="groupname"/>
      <xsl:choose>
        <xsl:when test="$field/adl:permission[@group=$groupname]">
          <xsl:value-of select="$field/adl:permission[@group=$groupname]/@permission"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="property-permission">
            <xsl:with-param name="property" select="$field/ancestor::adl:entity//adl:property[@name=$field/@name]"/>
            <xsl:with-param name="groupname" select="$groupname"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

</xsl:stylesheet>