<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xslo="http://www.w3.org/1999/XSL/TransformAlias"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
	<!--
    Application Description Language framework
    localise-transform.xslt
    
    (c) 2007 Cygnet Solutions Ltd
    
    Highly experiemental.
	It is not possible in XSLT to do conditional includes, so you can't do, for example
	<xsl:include href="concat( 'i18n-', $locale, '-include.xslt')"/>
	The object of this file is to take an xslt transform and rewrite the localisation 
	for the specified locale, passing everything else through unaltered.
    
    $Author: sb $
    $Revision: 1.1 $
    $Date: 2008-05-29 16:40:09 $
	-->
	<xsl:namespace-alias stylesheet-prefix="xslo" result-prefix="xsl"/>

	<xsl:output method="xml" indent="yes"/>

	<!-- The locale for which the localised transforms are generated. -->
	<xsl:param name="locale" select="en-GB"/>
	
	<!-- in practice, en-GB is our default locale for now -->
	<xsl:template match="xsl:include[href='i18n-en-GB-include.xslt']">
		<xslo:include>
			<xsl:attribute name="href">
				<xsl:value-of select="concat( 'i18n-', $locale, '-include.xslt')"/>
			</xsl:attribute>
		</xslo:include>
	</xsl:template>

	<!-- if this works, we may use a magic token in the master file(s) -->
	<xsl:template match="xsl:include[href='replace-with-localisation-include-name']">
		<xslo:include>
			<xsl:attribute name="href">
				<xsl:value-of select="concat( 'i18n-', $locale, '-include.xslt')"/>
			</xsl:attribute>
		</xslo:include>
	</xsl:template>
	
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
