<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
	xmlns="http://cygnets.co.uk/schemas/adl-1.2"
	xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt">
	
	<!--
    Application Description Language framework
    i18n-en-GB-include.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Internationalisation support for British English; use
	this as a template to provide internationalisation support
	for other natural languages.
	
	In general all templates in this file are
	(i) named;
	(ii) have names starting with 'i18n-';
	(iii) take arguments which are strings only, not nodesets.
	Templates are listed in alphabetical order.
    
    $Author: sb $
    $Revision: 1.1 $
    $Date: 2008-05-26 14:40:08 $
	-->

	<xsl:output method="xml" indent="yes"/>

	<xsl:template name="i18n-add-a-new">
		<!-- a string, presumed to be the name of a domain entity -->
		<xsl:param name="entity-name"/>
		<xsl:value-of select="concat( 'Add a new ', $entity-name)"/>
	</xsl:template>

	<xsl:template name="i18n-bad-format">
		<!-- a string, presumed to be the name of a format definition -->
		<xsl:param name="format-name"/>
		<xsl:value-of select="concat( 'Does not meet the format requirements for', $format-name)"/>
	</xsl:template>

	<xsl:template name="i18n-delete-prompt">
		<xsl:value-of select="'To delete this record'"/>
	</xsl:template>

	<xsl:template name="i18n-indefinite-article">
		<!-- a string, presumed to be a noun- e.g. the name of an entity -->
		<xsl:param name="noun"/>
		<xsl:variable name="initial" select="substring( $noun, 1, 1)"/>
		<xsl:choose>
			<xsl:when test="$initial = 'A' or $initial = 'a'">an</xsl:when>
			<xsl:when test="$initial = 'E' or $initial = 'e'">an</xsl:when>
			<xsl:when test="$initial = 'I' or $initial = 'i'">an</xsl:when>
			<xsl:when test="$initial = 'O' or $initial = 'o'">an</xsl:when>
			<xsl:when test="$initial = 'U' or $initial = 'u'">an</xsl:when>
			<xsl:otherwise>a</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="i18n-list">
		<!-- a string, presumed to be the name of a domain entity -->
		<xsl:param name="entity-name"/>
		<xsl:variable name="plural">
			<xsl:call-template name="i18n-plural">
				<xsl:with-param name="noun" select="entity-name"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="concat( 'List', $plural)"/>
	</xsl:template>

	<xsl:template name="i18n-plural">
		<!-- a string, presumed to be a noun -->
		<xsl:param name="noun"/>
		<!-- English-laguage syntactic sugar of entity name -->
		<xsl:choose>
			<xsl:when test="$noun='Person'">People</xsl:when>
			<!-- add other special cases here -->
			<xsl:when test="starts-with( substring($noun, string-length($noun) ), 's')">
				<xsl:value-of select="concat( $noun, 'es')"/>
			</xsl:when>
			<xsl:when test="starts-with( substring($noun, string-length($noun) ), 'y')">
				<xsl:value-of select="concat( substring( $noun, 0, string-length($noun)), 'ies')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat( $noun, 's')"/>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<!-- the 'really delete' message, used in two-phase delete process -->
	<xsl:template name="i18n-really-delete">
		<xsl:value-of select="'Really delete'"/>
	</xsl:template>
	<!-- the 'cancel delete' message, used in two-phase delete process -->
	<xsl:template name="i18n-really-delete-no">
		<xsl:value-of select="'No, do not delete it'"/>
	</xsl:template>
	<!-- the 'confirm delete' message, used in two-phase delete process -->
	<xsl:template name="i18n-really-delete-yes">
		<xsl:value-of select="'Yes, do delete it'"/>
	</xsl:template>

	<xsl:template name="i18n-save-prompt">
		<xsl:value-of select="'To save this record'"/>
	</xsl:template>

	<xsl:template name="i18n-value-defined">
		<!-- a string, presumed to be the name of a property -->
		<xsl:param name="property-name"/>
		<!-- a string, presumed to be the name of a defined type -->
		<xsl:param name="definition-name"/>
		<xsl:variable name="aoran">
			<xsl:call-template name="i18n-indefinite-article">
				<xsl:with-param name="noun" select="$definition-name"/>
			</xsl:call-template>
		</xsl:variable>
					  
		<xsl:value-of select="concat( 'The value for ', $property-name, ' must be ', $aoran, ' ', $definition-name)"/>
	</xsl:template>

	<xsl:template name="i18n-value-entity">
		<!-- a string, presumed to be the name of a property -->
		<xsl:param name="property-name"/>
		<!-- a string, presumed to be the name of a domain entity -->
		<xsl:param name="entity-name"/>
		<xsl:variable name="aoran">
			<xsl:call-template name="i18n-indefinite-article">
				<xsl:with-param name="noun" select="$entity-name"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:value-of select="concat( 'The value for ', $property-name, ' must be ', $aoran, ' ', $entity-name)"/>
	</xsl:template>

	<xsl:template name="i18n-value-required">
		<!-- a string, presumed to be the name of a property -->
		<xsl:param name="property-name"/>
		<xsl:value-of select="concat( 'You must provide a value for', $property-name)"/>
	</xsl:template>

	<xsl:template name="i18n-value-type">
		<!-- a string, presumed to be the name of a property -->
		<xsl:param name="property-name"/>
		<!-- a string, presumed to be the name of a type -->
		<xsl:param name="type-name"/>
		<xsl:variable name="aoran">
			<xsl:call-template name="i18n-indefinite-article">
				<xsl:with-param name="noun" select="$type-name"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:value-of select="concat( 'The value for ', $property-name, ' must be ', $aoran, ' ', $type-name)"/>
	</xsl:template>
</xsl:stylesheet>
