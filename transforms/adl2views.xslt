<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
	xmlns="http://libs.cygnets.co.uk/adl/1.3/"
	xmlns:adl="http://libs.cygnets.co.uk/adl/1.3/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
				xmlns:exsl="urn:schemas-microsoft-com:xslt"
                extension-element-prefixes="exsl">
	<!--
    Application Description Language framework
    adl2views.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into velocity view templates
    
    $Author: sb $
    $Revision: 1.39 $
    $Date: 2009-04-28 13:44:51 $
	-->
	<!-- WARNING WARNING WARNING: Do NOT reformat this file! 
		Whitespace (or lack of it) is significant! -->

	<xsl:include href="base-type-include.xslt"/>
	<xsl:include href="permissions-include.xslt"/>

	<xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

	<!-- The locale for which these views are generated 
      TODO: we need to generate views for each available locale, but this is not
      yet implemented. When it is we will almost certainly still need a 'default locale' -->
	<xsl:param name="locale" select="en-GB"/>

	<!-- bug 1896 : boilerplate text in views should be tailored to the locale of
		the expected user. Unfortunately I haven't yet worked out how to do
		conditional includes in XSLT, so this is a step on the way to a solution,
		not a solution in itself. -->
	<xsl:include href="i18n-en-GB-include.xslt"/>

	<!-- whether or not to auto-generate site navigation - by default, don't -->
	<xsl:param name="generate-site-navigation" select="'false'"/>

	<!-- whether or not to layout errors - they may be in the default layout -->
	<xsl:param name="show-errors" select="'false'"/>
	<!-- whether or not to layout messages - they may be in the default layout -->
	<xsl:param name="show-messages" select="'false'"/>

	<!-- the maximum width, in characters, we're prepared to allocate to widgets -->
	<xsl:param name="max-widget-width" select="40"/>

	<!-- the name and version of the product being built -->
	<xsl:param name="product-version" select="'Application Description Language Framework'"/>

	<!-- bug 1800 : the name of the Velocity layout to use. If you are to 
		be able to usefully define content in ADL, then the default ADL layout 
		needs to be empty, but if ADL-generated pages are to 'play nice' in
		largely non-ADL applications, they must be able to use standard layouts.
		If you are going to use a non-default layout, however, you're responsible
		for making sure it loads all the scripts, etc, that an ADL controller 
		expects. -->
	<xsl:param name="layout-name"/>
	<!-- bug 1800 : the name of the area (i.e. URL path part) to use -->
	<xsl:param name="area-name" select="auto"/>
	<!-- the base url of the whole site -->
	<xsl:param name="site-root" select="'..'"/>
	<!-- Whether to authenticate at application or at database layer. 
    If not 'Application', then 'Database'. -->
	<xsl:param name="authentication-layer" select="'Application'"/>

	<xsl:template match="adl:application">
		<output>
			<!-- 'output' is a dummy wrapper root tag to make the entire output work as
				an XML document; the actual output later gets cut into chunks and the
				wrapper tag is discarded. -->
			<xsl:apply-templates select="adl:entity"/>
			<!-- make sure extraneous junk doesn't get into the last file generated,
				by putting it into a separate file -->
			<xsl:text>
			  </xsl:text>
			<xsl:comment> [ cut here: next file 'tail.txt' ] </xsl:comment>
		</output>
	</xsl:template>

	<xsl:template match="adl:entity[@foreign='true']"/>
	<!-- Don't bother generating anything for foreign entities -->

	<xsl:template match="adl:entity">
		<xsl:comment>Layout is <xsl:value-of select="$layout-name"/></xsl:comment>
		<xsl:choose>
			<xsl:when test="$layout-name">
				<xsl:apply-templates select="." mode="non-empty-layout"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="empty-layout"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- generate views for an entity, assuming a non-empty layout - i.e. 
    I'm not responsible for the html, the head, or for the body tag -->
	<xsl:template match="adl:entity" mode="non-empty-layout">
		<xsl:variable name="keyfield">
			<xsl:choose>
				<xsl:when test="adl:key/adl:property">
					<xsl:value-of select="adl:key/adl:property[position()=1]/@name"/>
				</xsl:when>
				<xsl:otherwise>[none]</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:apply-templates select="adl:form" mode="non-empty-layout"/>
		<xsl:apply-templates select="adl:list" mode="non-empty-layout"/>
		<xsl:text>
      </xsl:text>
		<xsl:comment> [ cut here: next file '<xsl:value-of select="concat( @name, '/maybedelete.auto.vm')"/>' ] </xsl:comment>
		<xsl:text>
      </xsl:text>
		<xsl:variable name="really-delete">
			<xsl:call-template name="i18n-really-delete"/>
		</xsl:variable>
		#set( $title = "<xsl:value-of select="concat( $really-delete, ' ', @name)"/> $instance.UserIdentifier")
		<xsl:comment>
			<xsl:value-of select="$product-version"/>

			Auto generated Velocity maybe-delete form for <xsl:value-of select="@name"/>,
			generated from ADL.

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>
		</xsl:comment>
		<xsl:call-template name="maybe-delete">
			<xsl:with-param name="entity" select="."/>
		</xsl:call-template>
	</xsl:template>

	<!-- generate views for an entity, assuming an empty layout 
			(i.e. I'm responsible for html, head and body tags) -->
		<xsl:template match="adl:entity" mode="empty-layout">
			<xsl:variable name="keyfield">
				<xsl:choose>
					<xsl:when test="adl:key/adl:property">
						<xsl:value-of select="adl:key/adl:property[position()=1]/@name"/>
					</xsl:when>
					<xsl:otherwise>[none]</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:apply-templates select="adl:form" mode="empty-layout"/>
			<xsl:apply-templates select="adl:list" mode="empty-layout"/>
			<xsl:text>
			</xsl:text>
			<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( @name, '/maybedelete.auto.vm')"/>' ]</xsl:comment>
			<xsl:text>
			</xsl:text>
			<html>
				<xsl:variable name="really-delete">
					<xsl:call-template name="i18n-really-delete"/>
				</xsl:variable>
				#set( $title = "<xsl:value-of select="concat( $really-delete, ' ', @name)"/> $instance.UserIdentifier")
				<head>
					<xsl:call-template name="head"/>
					<xsl:comment>
						Auto generated Velocity maybe-delete form for <xsl:value-of select="@name"/>,
						generated from ADL.

						Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>

						<xsl:value-of select="/adl:application/@revision"/>
					</xsl:comment>
					<xsl:call-template name="install-scripts"/>
				</head>
				<body>
					<xsl:call-template name="top"/>
					<xsl:call-template name="maybe-delete">
						<xsl:with-param name="entity" select="."/>
					</xsl:call-template>
					<xsl:call-template name="foot"/>
				</body>
			</html>
		</xsl:template>

		<!-- the guts of the maybe-delete form, whether or not we're using an empty layout -->
    <xsl:template name="maybe-delete">
      <xsl:param name="entity"/>
      <form action="delete.rails" method="post">
        <xsl:for-each select="$entity/adl:key/adl:property">
          <xsl:choose>
            <xsl:when test="@type='entity'">
              <xsl:variable name="entityname" select="@entity"/>
              <xsl:variable name="entitykeyname" select="//adl:entity[@name=$entityname]/adl:key/adl:property[position()=1]/@name"/>
              <input type="hidden">
                <xsl:attribute name="name">
                  <xsl:value-of select="concat( 'instance.', @name)"/>
                </xsl:attribute>
                <xsl:attribute name="value">
                  <xsl:value-of select="concat('$instance.', @name, '.', $entitykeyname)"/>
                </xsl:attribute>
              </input>
            </xsl:when>
            <xsl:otherwise>
              <input type="hidden">
                <xsl:attribute name="name">
                  <xsl:value-of select="concat( 'instance.', @name)"/>
                </xsl:attribute>
                <xsl:attribute name="value">
                  <xsl:value-of select="concat('$instance.', @name)"/>
                </xsl:attribute>
              </input>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <table>
          <tr align="left" valign="top" class="actionDangerous">
            <td class="actionDangerous">
				<xsl:call-template name="i18n-really-delete"/>
			</td>
            <td class="widget">
              <select name="reallydelete">
                <option value="false">
					<xsl:call-template name="i18n-really-delete-no"/>
				</option>
                <option value="true">
					<xsl:call-template name="i18n-really-delete-yes"/>
				</option>
              </select>
            </td>
            <td class="actionDangerous" style="text-align:right">
              <input type="submit" name="command" value="Go!" />
            </td>
          </tr>
        </table>
      </form>
    </xsl:template>

  <!-- layout of forms -->
	<xsl:template match="adl:form" mode="non-empty-layout">
		<xsl:variable name="form" select="."/>
		<xsl:text>
		</xsl:text>
		<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( ancestor::adl:entity/@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
		<xsl:text>
      </xsl:text>
		<xsl:comment>
			<xsl:value-of select="$product-version"/>

			Auto generated Velocity <xsl:value-of select="@name"/> form for <xsl:value-of select="ancestor::adl:entity/@name"/>,
			generated from ADL.

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>
			Generation parameters were:
			locale: <xsl:value-of select="$locale"/>
			generate-site-navigation: <xsl:value-of select="$generate-site-navigation"/>
			show-errors: <xsl:value-of select="$show-errors"/>
			show-messages: <xsl:value-of select="$show-messages"/>
			max-widget-width: <xsl:value-of select="$max-widget-width"/>
			product-version: <xsl:value-of select="$product-version"/>
			layout-name: <xsl:value-of select="$layout-name"/>
			area-name: <xsl:value-of select="$area-name"/>

			<xsl:value-of select="/adl:application/@revision"/>
		</xsl:comment>
		#capturefor( title)
    #if ( $instance)
		#if ( ! $instance.IsNew)
		<xsl:value-of select="concat( 'Edit ', ' ', ancestor::adl:entity/@name)"/> $instance.UserIdentifier
		#else
		<xsl:call-template name="i18n-add-a-new">
			<xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
		</xsl:call-template>
    #end
    #else
    <xsl:call-template name="i18n-add-a-new">
      <xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
    </xsl:call-template>
    #end
    #end
    #capturefor( headextras)
    <xsl:call-template name="head"/>
		<xsl:call-template name="generate-head-javascript">
			<xsl:with-param name="form" select="."/>
		</xsl:call-template>

		${StylesHelper.InstallStylesheet( "Epoch")}

		<style type="text/css">
			<xsl:for-each select="ancestor::adl:entity//adl:property[@required='true']">
				#<xsl:value-of select="concat( 'advice-required-instance_', @name)"/>
				{
				color: white;
				background-color: rgb( 198, 0, 57);
				font-style: italic;
				}
			</xsl:for-each>
		</style>
		#end
		#capturefor(bodyattributes)
		onload="performInitialisation()"
		#end
		<xsl:call-template name="top"/>
		<xsl:call-template name="form-content">
			<xsl:with-param name="form" select="."/>
		</xsl:call-template>
		<xsl:call-template name="foot"/>
	</xsl:template>

	<xsl:template match="adl:form" mode="empty-layout">
		<xsl:variable name="form" select="."/>
		<xsl:text>
		</xsl:text>
		<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( ancestor::adl:entity/@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
		<xsl:text>
		</xsl:text>
		<html>
			<xsl:comment>
        #if ( $instance)
				#if ( ! $instance.IsNew)
				#set( $title = "<xsl:value-of select="concat( 'Edit ', ' ', ancestor::adl:entity/@name)"/> $instance.UserIdentifier")
				#else
				#set( $title = "<xsl:call-template name="i18n-add-a-new">
					<xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
				</xsl:call-template>")
        #end
        #else
        #set( $title = "<xsl:call-template name="i18n-add-a-new">
          <xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
        </xsl:call-template>")
        #end
      </xsl:comment>
			<head>
				<xsl:call-template name="head"/>
				<xsl:comment>
					<xsl:value-of select="$product-version"/>

					Auto generated Velocity form for <xsl:value-of select="ancestor::adl:entity/@name"/>,
					generated from ADL.

					Generated using adl2views.xsl <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>
					Generation parameters were:
					locale: <xsl:value-of select="$locale"/>
					generate-site-navigation: <xsl:value-of select="$generate-site-navigation"/>
					show-errors: <xsl:value-of select="$show-errors"/>
					show-messages: <xsl:value-of select="$show-messages"/>
					max-widget-width: <xsl:value-of select="$max-widget-width"/>
					product-version: <xsl:value-of select="$product-version"/>
					layout-name: <xsl:value-of select="$layout-name"/>
					area-name: <xsl:value-of select="$area-name"/>
					<xsl:value-of select="/adl:application/@revision"/>
				</xsl:comment>
				<xsl:call-template name="install-scripts"/>
				<xsl:call-template name="generate-head-javascript">
					<xsl:with-param name="form" select="."/>
				</xsl:call-template>

				${StylesHelper.InstallStylesheet( "Epoch")}

				<style type="text/css">
					<xsl:for-each select="ancestor::adl:entity//adl:property[@required='true']">
						#<xsl:value-of select="concat( 'advice-required-instance_', @name)"/>
						{
						color: white;
						background-color: rgb( 198, 0, 57);
						font-style: italic;
						}
					</xsl:for-each>
				</style>
			</head>
			<body onload="performInitialisation()">
				<xsl:call-template name="top"/>
				<xsl:call-template name="form-content">
					<xsl:with-param name="form" select="."/>
				</xsl:call-template>
				<xsl:call-template name="foot"/>
			</body>
		</html>
	</xsl:template>

	<!-- the content of a form, whether or not the layout is empty -->
    <xsl:template name="form-content">
		<!-- an entity of type form -->
		<xsl:param name="form"/>
		<div class="content">
			<xsl:if test="$show-errors = 'true'">
				#if ( $errors)
					#if ( $errors.Count != 0)
						<ul class="errors">
							#foreach($e in $errors)
								#if($e.Message)
									<li>$t.Error($e)</li>
								#else
									<li>$t.Enc($e)</li>
								#end
							#end
						</ul>
					#end
				#end
			</xsl:if>
			<xsl:if test="$show-messages = 'true'">
				#if( $messages)
					#if ( $messages.Count != 0)
						<ul class="information">
							#foreach ( $message in $messages)
								<li>$message</li>
							#end
						</ul>
					#end
				#end
			</xsl:if>
			<form method="post" onsubmit="invokeSubmitHandlers( this)"  class="tabbed">
				<xsl:attribute name="action">
					<xsl:value-of select="concat( $form/@name, 'SubmitHandler.rails')"/>
				</xsl:attribute>
				<xsl:attribute name="name">
					<xsl:value-of select="$form/@name"/>
				</xsl:attribute>
				<xsl:attribute name="id">
					<xsl:value-of select="$form/@name"/>
				</xsl:attribute>
				<xsl:attribute name="enctype">
					<xsl:choose>
						<xsl:when test="$form/ancestor::adl:entity//adl:property[@type='uploadable']">
							<xsl:value-of select="'multipart/form-data'"/>
						</xsl:when>
						<xsl:when test="$form/ancestor::adl:entity//adl:property[@type='image']">
							<xsl:value-of select="'multipart/form-data'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'application/x-www-form-urlencoded'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<input type="hidden" name="currentpane" value="$!currentpane" />
				<xsl:for-each select="$form/ancestor::adl:entity/adl:key/adl:property">
					<xsl:variable name="keyname" select="@name"/>
					<xsl:choose>
						<xsl:when test="$form//adl:field[@property=$keyname]">
							<!-- it's already a field of the form - no need to add a hidden one -->
						</xsl:when>
						<xsl:otherwise>
							<!-- create a hidden widget for the natural primary key -->
							#if ( $instance)
							#if ( ! ( $instance.IsNew))
							${FormHelper.HiddenField( "instance.<xsl:value-of select="$keyname"/>")}
							#end
							#end
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<xsl:apply-templates select="$form/adl:fieldgroup"/>
				<div class="non-pane">
					<table>
						<xsl:choose>
							<xsl:when test="@properties='listed'">
								<xsl:apply-templates select="$form/adl:field|adl:auxlist|adl:verb"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates select="$form/ancestor::adl:entity/adl:property"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="$authentication-layer='Database'">
								<xsl:variable name="savegroups">
									<xsl:call-template name="entity-save-groups">
										<xsl:with-param name="entity" select="$form/ancestor::adl:entity"/>
									</xsl:call-template>
								</xsl:variable>
								<!-- NOTE! NOTE! NOTE! Whitespace is significant - any linefeeds inside the #if ( ) clause
								cause the Velocity parser to break! -->
								#if ( <xsl:for-each select="exsl:node-set( $savegroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
								<xsl:call-template name="save-widget-row"/>
								#end
								<xsl:variable name="deletegroups">
									<xsl:call-template name="entity-delete-groups">
										<xsl:with-param name="entity" select="$form/ancestor::adl:entity"/>
									</xsl:call-template>
								</xsl:variable>
								<!-- NOTE! NOTE! NOTE! Whitespace is significant - any linefeeds inside the #if ( ) clause
								cause the Velocity parser to break! -->
								#if ( <xsl:for-each select="exsl:node-set( $deletegroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
								<xsl:call-template name="delete-widget-row"/>
								#end
							</xsl:when>
							<xsl:when test="$authentication-layer='Application'">
								<xsl:call-template name="save-widget-row"/>
								<xsl:call-template name="delete-widget-row"/>
							</xsl:when>
						</xsl:choose>
					</table>
				</div>
			</form>
		</div>
	</xsl:template>

	<!-- output a complete table row containing a save widget -->
	<xsl:template name="save-widget-row">
		<tr class="actionSafe">
			<td class="actionSafe" colspan="2">
				<xsl:call-template name='i18n-save-prompt'/>
			</td>
			<td class="actionSafe" style="text-align:right">
				<button type="submit" name="command" value="store">Save this!</button>
			</td>
		</tr>
	</xsl:template>

	<!-- output a complete table row containing a delete widget -->
	<xsl:template name="delete-widget-row">
		<tr align="left" valign="top" class="actionDangerous">
			<td class="actionDangerous" colspan="2">
				#if ( $instance)
				#if ( $instance.NoDeleteReason)
				[ $instance.NoDeleteReason ]
				#else
				<xsl:call-template name="i18n-delete-prompt"/>
				#end
				#end
			</td>
			<td class="actionDangerous" style="text-align:right">
				#if ( $instance)
				#if ( $instance.NoDeleteReason)
				<button type="submit" disabled="disabled" title="$instance.NoDeleteReason"  name="command" value="delete">Delete this!</button>
				#else
				<button type="submit" name="command" value="delete">Delete this!</button>
				#end
				#end
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="adl:fieldgroup">
		<div class="tab-pane">
			<xsl:attribute name="id">
				<xsl:value-of select="concat( @name, 'pane')"/>
			</xsl:attribute>
			<xsl:attribute name="style">
				<xsl:choose>
					<xsl:when test="position() = 1"/>
					<xsl:otherwise>display: none</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<h3 class="title">
				<xsl:call-template name="showprompt">
					<xsl:with-param name="node" select="."/>
					<xsl:with-param name="fallback" select="@name"/>
					<xsl:with-param name="entity" select="ancestor::adl:entity"/>
					<xsl:with-param name="locale" select="$locale"/>
				</xsl:call-template>
			</h3>
			<table>
				<xsl:apply-templates select="adl:field|adl:verb|adl:auxlist"/>
			</table>
		</div>
	</xsl:template>

	<xsl:template match="adl:auxlist">
		<xsl:variable name="listprop" select="@property"/>
		<xsl:variable name="farent" select="ancestor::adl:entity//adl:property[@name=$listprop]/@entity"/>
		<xsl:variable name="nearent" select="ancestor::adl:entity/@name"/>
		<xsl:variable name="farid">
			<xsl:value-of select="//adl:entity[@name=$farent]/adl:key//adl:property[position()=1]/@name"/>
		</xsl:variable>
		<xsl:variable name="farkey">
			<xsl:choose>
				<xsl:when test="//adl:entity[@name=$farent]//adl:property[@entity=$nearent]/@farkey">
					<xsl:value-of select="//adl:entity[@name=$farent]//adl:property[@entity=$nearent]/@farkey"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="//adl:entity[@name=$farent]//adl:property[@entity=$nearent]/@name"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="nearkey">
			<xsl:choose>
				<xsl:when test="ancestor::adl:entity/adl:key/adl:property[position()=1 and @type='entity']">
					<xsl:value-of select="concat( ancestor::adl:entity/adl:key/adl:property[position()=1]/@name, '_Value')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="ancestor::adl:entity/adl:key/adl:property[position()=1]/@name"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="action" select="concat( '../', $farent, '/', @onselect)"/>
		<xsl:if test="@canadd='true'">
			<tr>
				<td>
					<xsl:attribute name="colspan">
						<xsl:value-of select="count( field)"/>
					</xsl:attribute>
					<a>
						<xsl:attribute name="href">
							<xsl:value-of select="concat( $action, 'With', $farkey, '.rails?', $farkey, '=$instance.', $nearkey)"/>
						</xsl:attribute>
						<xsl:call-template name="i18n-add-a-new">
							<xsl:with-param name="entity-name" select="$farent"/>
						</xsl:call-template>
					</a>
				</td>
			</tr>
		</xsl:if>
		<tr>
			<td>
				<xsl:attribute name="colspan">
					<xsl:value-of select="count( field)"/>
				</xsl:attribute>

				<xsl:choose>
					<xsl:when test="@properties='listed'">
						<xsl:comment>auxlist with listed fields: <xsl:value-of select="$farent/@name"/></xsl:comment>
						<xsl:call-template name="internal-with-fields-list">
							<xsl:with-param name="entity" select="//adl:entity[@name=$farent]"/>
							<xsl:with-param name="fields" select="adl:field"/>
							<xsl:with-param name="instance-list" select="concat( 'instance.', $listprop)"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:comment>auxlist with computed fields: <xsl:value-of select="$farent/@name"/></xsl:comment>
						<xsl:call-template name="internal-with-properties-list">
							<xsl:with-param name="entity" select="//adl:entity[@name=$farent]"/>
							<xsl:with-param name="properties" select="//adl:entity[@name=$farent]//adl:property[(@distinct='user' or @distinct='all') and not( @type='link' or @type='list')]"/>
							<xsl:with-param name="instance-list" select="concat( 'instance.', $listprop)"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="adl:verb">
		<xsl:variable name="class">
			<xsl:choose>
				<xsl:when test="@dangerous='true'">actionDangerous</xsl:when>
				<xsl:otherwise>actionSafe</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- don't emit a verb unless there is an instance for it to act on -->
		#if( $instance)
    #if( ! $instance.IsNew)
		<tr>
			<xsl:attribute name="class">
				<xsl:value-of select="$class"/>
			</xsl:attribute>
			<td colspan="2">
				<xsl:attribute name="class">
					<xsl:value-of select="$class"/>
				</xsl:attribute>
				<xsl:apply-templates select="adl:help[@locale = $locale]"/>
			</td>
			<td style="text-align:right">
				<xsl:attribute name="class">
					<xsl:value-of select="$class"/>
				</xsl:attribute>
				<button name="command">
					<xsl:attribute name="value">
						<xsl:value-of select="@verb"/>
					</xsl:attribute>
					<xsl:call-template name="showprompt">
						<xsl:with-param name="node" select="."/>
						<xsl:with-param name="fallback" select="@verb"/>
					</xsl:call-template>
				</button>
			</td>
		</tr>
    #end
		#end
	</xsl:template>

	<xsl:template match="adl:field">
		<xsl:variable name="propname">
			<xsl:value-of select="@property"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="ancestor::adl:entity//adl:property[@name=$propname]">
				<!-- there is a real property -->
				<xsl:apply-templates select="ancestor::adl:entity//adl:property[@name=$propname]">
					<xsl:with-param name="oddness">
						<xsl:choose>
							<xsl:when test="position() mod 2 = 0">even</xsl:when>
							<xsl:otherwise>odd</xsl:otherwise>
						</xsl:choose>
					</xsl:with-param>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- it's presumably intended to be a computed field -->
				<xsl:comment>
					Computed field (<xsl:value-of select="$propname"/>)? TODO: Not yet implememented
				</xsl:comment>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="adl:property[@type='message']">
		<!-- HIHGLY experimental - an internationalised message -->
		<xsl:param name="oddness" select="odd"/>
		<tr>
			<xsl:attribute name="class">
				<xsl:value-of select="$oddness"/>
			</xsl:attribute>
			<td class="label">
				${FormHelper.LabelFor( "instance.<xsl:value-of select="@name"/>", "<xsl:call-template name="showprompt">
					<xsl:with-param name="node" select="."/>
					<xsl:with-param name="fallback" select="@name"/>
				</xsl:call-template>")}
			</td>
			<td class="widget" colspan="2">
				#if( $instance)
				#if( <xsl:value-of select="concat( '$instance.', @name)"/>)
				<xsl:value-of select="concat( '$t.Msg( $instance.', @name, ')')"/>
				#else
				<input type="text">
					<xsl:attribute name="name">
						<xsl:value-of select="concat('i18n.instance.', @name)"/>
					</xsl:attribute>
				</input>
				#end
				#else
				<input type="text">
					<xsl:attribute name="name">
						<xsl:value-of select="concat('i18n.instance.', @name)"/>
					</xsl:attribute>
				</input>
				#end
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="adl:property[@type='link'or @type='list']">
		<!-- note! this template is only intended to match properties in the context of a form:
      it may be we need to add a mode to indicate this! -->
		<!-- for links and lists we implement a shuffle widget, which extends over both columns -->
		<xsl:param name="oddness" select="odd"/>
		<tr>
			<xsl:attribute name="class">
				<xsl:value-of select="$oddness"/>
			</xsl:attribute>
			<td class="label" rowspan="2">
				${FormHelper.LabelFor( "instance.<xsl:value-of select="@name"/>", "<xsl:call-template name="showprompt">
					<xsl:with-param name="node" select="."/>
					<xsl:with-param name="fallback" select="@name"/>
				</xsl:call-template>")}
			</td>
			<td class="widget shuffle" colspan="2">
				<xsl:choose>
					<xsl:when test="$authentication-layer = 'Database'">
						<xsl:variable name="property" select="."/>
						<xsl:variable name="readgroups">
							<xsl:call-template name="entity-read-groups">
								<xsl:with-param name="entity" select="//adl:entity[@name=$property/@entity]"/>
							</xsl:call-template>
						</xsl:variable>
						<!-- NOTE! NOTE! NOTE! Whitespace is significant - any linefeeds inside the #if ( ) clause cause the Velocity parser to break! -->
						#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
						<xsl:call-template name="shuffle-widget">
							<xsl:with-param name="property" select="."/>
						</xsl:call-template>
						#else
						[Not authorised]
						#end
					</xsl:when>
					<xsl:when test="$authentication-layer = 'Application'">
						<xsl:call-template name="shuffle-widget">
							<xsl:with-param name="property" select="."/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>

			</td>
		</tr>
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="position() mod 2 = 0">even</xsl:when>
					<xsl:otherwise>odd</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<td class="help" colspan="2">
				<xsl:apply-templates select="adl:help[@locale = $locale]"/>
			</td>
		</tr>
	</xsl:template>

	<xsl:template name="shuffle-widget">
		<xsl:param name="property" select="."/>
    #if ( $instance)
    #if ( ! $instance.IsNew)
		<table class="shuffle">
			<tr>
				<td class="widget shuffle-all" rowspan="2">
					${ShuffleWidgetHelper.UnselectedOptions( "<xsl:value-of select="concat( $property/@name, '_unselected')"/>", <xsl:value-of select="concat( '$all_', $property/@name)"/>, $instance.<xsl:value-of select="$property/@name"/>)}
				</td>
				<td class="widget shuffle-action">
					<input type="button" value="include &gt;&gt;">
						<xsl:attribute name="onclick">
							<xsl:value-of select="concat( 'shuffle(', $property/@name, '_unselected, ', $property/@name, ')')"/>
						</xsl:attribute>
					</input>
				</td>
				<td class="widget shuffle-selected" rowspan="2">
					<xsl:variable name="entityname" select="$property/@entity"/>
					<xsl:variable name="foreignkey" select="$property/@farkey"/>
					<xsl:variable name="allow-shuffle-back">
						<xsl:choose>
							<xsl:when test="$property/@type='list' and //adl:entity[@name=$entityname]//adl:property[@name=$foreignkey and @required='true']">
								<xsl:value-of select="'false'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'true'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					${ShuffleWidgetHelper.SelectedOptions( "<xsl:value-of select="$property/@name"/>", $instance.<xsl:value-of select="$property/@name"/>, <xsl:value-of select="$allow-shuffle-back"/>)}
				</td>
			</tr>
			<tr>
				<td class="widget shuffle-action">
					<input type="button" value="&lt;&lt; exclude">
						<xsl:attribute name="onclick">
							<xsl:value-of select="concat( 'shuffle(', @name, ', ', @name, '_unselected)')"/>
						</xsl:attribute>
					</input>
				</td>
			</tr>
		</table>
    #else
    <i>You must create your <xsl:value-of select="$property/ancestor::adl:entity/@name"/> record before you can add <xsl:value-of select="$property/@name"/> to it</i>
    #end
    #end
	</xsl:template>

	<xsl:template match="adl:property">
		<xsl:param name="oddness" select="odd"/>
		<!-- note! this template is only intended to match properties in the context of a form:
			it may be we need to add a mode to indicate this! -->
		<xsl:variable name="property" select="."/>
		<xsl:variable name="editgroups">
			<xsl:call-template name="property-edit-groups">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="insertgroups">
			<xsl:call-template name="property-insert-groups">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="readgroups">
			<xsl:call-template name="property-read-groups">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
			<tr>
				<xsl:attribute name="class">
					<xsl:value-of select="$oddness"/>
				</xsl:attribute>
				<td class="label">
					${FormHelper.LabelFor( "instance.<xsl:value-of select="@name"/>", "<xsl:call-template name="showprompt">
						<xsl:with-param name="fallback" select="@name"/>
					</xsl:call-template>")}
				</td>
				<td class="widget">
					<xsl:choose>
						<xsl:when test="$authentication-layer = 'Application'">
							<xsl:call-template name="property-widget">
								<xsl:with-param name="property" select="."/>
								<xsl:with-param name="mode" select="'Editable'"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="$authentication-layer = 'Database'">
							<xsl:if test="exsl:node-set( $editgroups)/*">
								<!-- NOTE! NOTE! NOTE! Whitespace is significant - any linefeeds inside the #if ( ) clause
								cause the Velocity parser to break! -->
								#if ( <xsl:for-each select="exsl:node-set( $editgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
								<xsl:choose>
									<xsl:when test="$property/@immutable='true'">
										<xsl:call-template name="property-widget">
											<xsl:with-param name="property" select="."/>
											<xsl:with-param name="mode" select="'Immutable'"/>
										</xsl:call-template>
									</xsl:when>
									<xsl:otherwise>
										<xsl:call-template name="property-widget">
											<xsl:with-param name="property" select="."/>
											<xsl:with-param name="mode" select="'Editable'"/>
										</xsl:call-template>
									</xsl:otherwise>
								</xsl:choose>
								#else
							</xsl:if>
							<xsl:if test="exsl:node-set( $insertgroups)/*">
								#if ( <xsl:for-each select="exsl:node-set( $insertgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
								<xsl:call-template name="property-widget">
									<xsl:with-param name="property" select="."/>
									<xsl:with-param name="mode" select="'Immutable'"/>
								</xsl:call-template>
								#else
							</xsl:if>
							<xsl:if test="exsl:node-set( $readgroups)/*">
								#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
								<xsl:call-template name="property-widget">
									<xsl:with-param name="property" select="."/>
									<xsl:with-param name="mode" select="'DisplayAndHidden'"/>
								</xsl:call-template>
								#else
							</xsl:if>
								[Not authorised]
							<xsl:if test="exsl:node-set( $readgroups)/*">
								#end
							</xsl:if>
							<xsl:if test="exsl:node-set( $insertgroups)/*">
								#end
							</xsl:if>
							<xsl:if test="exsl:node-set( $editgroups)/*">
								#end
							</xsl:if>
						</xsl:when>
					</xsl:choose>
				</td>
				<td class="help">
					<xsl:apply-templates select="adl:help[@locale = $locale]"/>
				</td>
			</tr>
	</xsl:template>


	<!-- layout of lists -->
	<!-- layout of a list assuming a non-empty layout -->
	<xsl:template match="adl:list" mode="non-empty-layout">
		<xsl:text>
		</xsl:text>
		<xsl:comment> [ cut here: next file '<xsl:value-of select="concat( ../@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
		<xsl:text>
        </xsl:text>
		<xsl:variable name="withpluralsuffix">
			<xsl:call-template name="i18n-plural">
				<xsl:with-param name="noun" select="ancestor::adl:entity/@name"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:comment>
			<xsl:value-of select="$product-version"/>

			Auto generated Velocity list for <xsl:value-of select="@name"/>,
			generated from ADL.

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>
			Generation parameters were:
			locale: <xsl:value-of select="$locale"/>
			generate-site-navigation: <xsl:value-of select="$generate-site-navigation"/>
			show-errors: <xsl:value-of select="$show-errors"/>
			show-messages: <xsl:value-of select="$show-messages"/>
			max-widget-width: <xsl:value-of select="$max-widget-width"/>
			product-version: <xsl:value-of select="$product-version"/>
			layout-name: <xsl:value-of select="$layout-name"/>
			area-name: <xsl:value-of select="$area-name"/>
		</xsl:comment>

		#capturefor( title)
		<xsl:value-of select="normalize-space( concat( 'List ', $withpluralsuffix))"/>
		#end
		#capturefor( headextras)
		<xsl:call-template name="head"/>
		#end
		<xsl:call-template name="top"/>
		<xsl:call-template name="list">
			<xsl:with-param name="list" select="."/>
		</xsl:call-template>
		<xsl:call-template name="foot"/>
	</xsl:template>


	<xsl:template match="adl:option">
		<option>
			<xsl:attribute name="value">
				<xsl:value-of select="@value"/>
			</xsl:attribute>
			<xsl:attribute name="id">
				<xsl:value-of select="concat( ancestor::adl:property/@name, '-', @value)"/>
			</xsl:attribute>
			<xsl:call-template name="showprompt">
				<xsl:with-param name="fallback" select="@value"/>
			</xsl:call-template>
		</option>
	</xsl:template>
	
	
	<!-- layout of a list assuming an empty layout -->
		<xsl:template match="adl:list" mode="empty-layout">
			<xsl:variable name="action" select="@onselect"/>
			<xsl:text>
			</xsl:text>
			<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( ../@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
			<xsl:text>
			</xsl:text>
			<xsl:variable name="withpluralsuffix">
				<xsl:call-template name="i18n-plural">
					<xsl:with-param name="noun" select="ancestor::adl:entity/@name"/>
				</xsl:call-template>
			</xsl:variable>
			<html>
			  <head>
				  #set( $title = "<xsl:value-of select="normalize-space( concat( 'List ', $withpluralsuffix))"/>")
				  <xsl:call-template name="head"/>
				  <xsl:comment>
					  <xsl:value-of select="$product-version"/>
					  Auto generated Velocity list for <xsl:value-of select="ancestor::adl:entity/@name"/>,
					  generated from ADL.

					  Generated using adl2listview.xsl <xsl:value-of select="substring( '$Revision: 1.39 $', 10)"/>
					  Generation parameters were:
					  locale: <xsl:value-of select="$locale"/>
					  generate-site-navigation: <xsl:value-of select="$generate-site-navigation"/>
					  show-errors: <xsl:value-of select="$show-errors"/>
					  show-messages: <xsl:value-of select="$show-messages"/>
					  max-widget-width: <xsl:value-of select="$max-widget-width"/>
					  product-version: <xsl:value-of select="$product-version"/>
					  layout-name: <xsl:value-of select="$layout-name"/>
					  area-name: <xsl:value-of select="$area-name"/>
				  </xsl:comment>
				  <xsl:call-template name="install-scripts"/>
			  </head>
			  <body>
				  <xsl:call-template name="top"/>
				  <xsl:call-template name="list">
					  <xsl:with-param name="list" select="."/>
				  </xsl:call-template>
				  <xsl:call-template name="foot"/>
			  </body>
		  </html>
	  </xsl:template>

	  <!-- layout the content of a list, whether or not the layout is empty -->
	  <xsl:template name="list">
		  <!-- an entity of type adl:list -->
		  <xsl:param name="list"/>
		  <div class="content">
			  <div class="controls">
				  <span class="pagination status">
					  Showing $instances.FirstItem - $instances.LastItem of $instances.TotalItems
				  </span>
				  <span class="pagination control">
					  #if($instances.HasFirst) $PaginationHelper.CreatePageLink( 1, "&lt;&lt;" ) #end
					  #if(!$instances.HasFirst) &lt;&lt; #end
				  </span>
				  <span class="pagination control">
					  #if($instances.HasPrevious) $PaginationHelper.CreatePageLink( $instances.PreviousIndex, "&lt;" ) #end
					  #if(!$instances.HasPrevious) &lt; #end
				  </span>
				  <span class="pagination control">
					  #if($instances.HasNext) $PaginationHelper.CreatePageLink( $instances.NextIndex, "&gt;" ) #end
					  #if(!$instances.HasNext) &gt; #end
				  </span>
				  <span class="pagination control">
					  #if($instances.HasLast) $PaginationHelper.CreatePageLink( $instances.LastIndex, "&gt;&gt;" ) #end
					  #if(!$instances.HasLast) &gt;&gt; #end
				  </span>
				  <xsl:if test="$list/../adl:form">
					  <span class="add">
						  <a>
							  <xsl:attribute name="href">
								  <xsl:value-of select="concat( ancestor::adl:entity/adl:form[position()=1]/@name, '.rails')"/>
							  </xsl:attribute>
							  <xsl:call-template name="i18n-add-a-new">
								  <xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
							  </xsl:call-template>
						  </a>
					  </span>
				  </xsl:if>
			  </div>
			  <form>
				  <xsl:attribute name="action">
					  <xsl:value-of select="concat( $list/@name, '.rails')"/>
				  </xsl:attribute>
				  <xsl:call-template name="internal-with-fields-list">
					  <xsl:with-param name="entity" select="$list/ancestor::adl:entity"/>
					  <xsl:with-param name="fields" select="$list/adl:field"/>
					  <xsl:with-param name="can-search" select="'true'"/>
				  </xsl:call-template>
			  </form>
		  </div>
	  </xsl:template>

	  <xsl:template name="internal-with-fields-list">
		  <!-- a node-list of entities of type 'adl:field' or 'adl:field', each indicating a property 
			of the same entity, to be shown in columns of this list -->
		  <xsl:param name="fields"/>
		  <!-- the entity of type 'adl:entity' on which the properties for all those fields can be found -->
		  <xsl:param name="entity"/>
		  <!-- the name of the list of instances of this entity, available to Velocity at runtime 
				as an ICollection, which is to be layed out in this list -->
		  <xsl:param name="instance-list" select="'instances'"/>
		  <!-- NOTE NOTE NOTE: To be searchable, internal-with-fields-list must not only be called with can-search
			equal to 'true', but also within a form! -->
		  <!-- NOTE NOTE NOTE: It's obvious that internal-with-fields-list and internal-with-properties-list
			ought to be replaced with a single template, but that template proves to be extremely hard to get 
			right -->
		  <xsl:param name="can-search"/>
		  <table>
			  <tr>
				  <xsl:for-each select="$fields">
					  <xsl:variable name="field" select="."/>
					  <th>
						  <xsl:call-template name="showprompt">
							<xsl:with-param name="node" select="."/>
							<xsl:with-param name="fallback" select="@property"/>
							<xsl:with-param name="entity" select="$entity"/>
							<xsl:with-param name="locale" select="$locale"/>
						  </xsl:call-template>
					  </th>
				  </xsl:for-each>
				  <xsl:for-each select="$entity/adl:form">
					  <th>-</th>
				  </xsl:for-each>
			  </tr>
			  <xsl:if test="$can-search = 'true'">
				  <tr class="search">
					  <xsl:for-each select="$fields">
						  <xsl:variable name="field" select="."/>
						  <td class="search">
							  <xsl:variable name="size">
								  <xsl:choose>
									  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='string'">
										  <xsl:choose>
											  <xsl:when test="$entity//adl:property[@name=$field/@property]/@size &gt; 20">20</xsl:when>
											  <xsl:otherwise>
												  <xsl:value-of select="$entity//adl:property[@name=$field/@property]/@size"/>
											  </xsl:otherwise>
										  </xsl:choose>
									  </xsl:when>
									  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='integer'">8</xsl:when>
									  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='real'">8</xsl:when>
									  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='money'">8</xsl:when>
									  <!-- xsl:when test="$entity//adl:property[@name=$field/@property]/@type='message'">20</xsl:when doesn't work yet -->
									  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='text'">20</xsl:when>
									  <!-- xsl:when test="$entity//adl:property[@name=$field/@property]/@type='enity'">20</xsl:when doesn't work yet -->
									  <xsl:otherwise>0</xsl:otherwise>
								  </xsl:choose>
							  </xsl:variable>
							  <xsl:if test="$size != 0">
								  <input>
									  <xsl:attribute name="name">
										  <xsl:value-of select="concat('search_',$entity//adl:property[@name=$field/@property]/@name)"/>
									  </xsl:attribute>
									  <xsl:attribute name="size">
										  <xsl:value-of select="$size"/>
									  </xsl:attribute>
									  <xsl:attribute name="value">
										  <xsl:value-of select="concat( '$!search_', $entity//adl:property[@name=$field/@property]/@name)"/>
									  </xsl:attribute>
								  </input>
							  </xsl:if>
						  </td>
					  </xsl:for-each>
					  <td>
						  <input type="submit" name="search-button" value="Search!"/>
					  </td>
				  </tr>
			  </xsl:if>
			  <xsl:if test="not( $entity/@name)">
				  <xsl:message terminate="yes">
					  Unknown entity whilst trying to generate list
				  </xsl:message>
			  </xsl:if>
			  <xsl:variable name="readgroups">
				  <xsl:call-template name="entity-read-groups">
					  <xsl:with-param name="entity" select="$entity"/>
				  </xsl:call-template>
			  </xsl:variable>
			  <xsl:choose>
				  <xsl:when test="$authentication-layer = 'Application'">
					  <xsl:call-template name="internal-with-fields-rows">
						  <xsl:with-param name="instance-list" select="$instance-list"/>
						  <xsl:with-param name="entity" select="$entity"/>
						  <xsl:with-param name="fields"	select="$fields"/>
					  </xsl:call-template>
				  </xsl:when>
				  <xsl:when test="$authentication-layer = 'Database'">
					<!-- NOTE NOTE NOTE: This is whitespace-sensitive! -->
					#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
					<xsl:call-template name="internal-with-fields-rows">
						<xsl:with-param name="instance-list" select="$instance-list"/>
						<xsl:with-param name="entity" select="$entity"/>
						<xsl:with-param name="fields" select="$fields"/>
					</xsl:call-template>
					#else
					<tr>
						<td colspan="5">[You are not authorised to view this data]</td>
					</tr>
					#end
				  </xsl:when>
			  </xsl:choose>
		  </table>
	  </xsl:template>

	<xsl:template name="internal-with-fields-rows">
		<xsl:param name="instance-list"/>
		<xsl:param name="entity"/>
		<xsl:param name="fields"/>
		#foreach( <xsl:value-of select="concat( '$', $entity/@name)"/> in <xsl:value-of select="concat('$', $instance-list)"/>)
		#if ( $velocityCount % 2 == 0)
		#set( $oddity = "even")
		#else
		#set( $oddity = "odd")
		#end
		<tr class="$oddity">
			<xsl:for-each select="$fields">
				<xsl:variable name="field" select="."/>
				<xsl:call-template name="list-field">
					<xsl:with-param name="entity" select="$entity"/>
					<xsl:with-param name="property" select="$entity//adl:property[@name=$field/@property]"/>
					<xsl:with-param name="objectvar" select="$entity/@name"/>
				</xsl:call-template>
			</xsl:for-each>
			<xsl:variable name="keys">
				<xsl:call-template name="entity-keys-fragment">
					<xsl:with-param name="entity" select="$entity"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:for-each select="$entity/adl:form">
				<!-- by default create a link to each form declared for the entity. 
                    We probably need a means of overriding this -->
				<td>
					<a>
						<xsl:attribute name="href">
							<xsl:value-of select="concat( '../', $entity/@name, '/', @name, '.rails', $keys)"/>
						</xsl:attribute>
						<xsl:value-of select="@name"/>!
					</a>
				</td>
			</xsl:for-each>
		</tr>
		#end
	</xsl:template>

	<xsl:template name="internal-with-properties-list">
		<!-- a node-list of entities of type 'adl:property', each a property of the same entity, to be shown
			in columns of this list -->
		<xsl:param name="properties"/>
		<!-- the entity of type 'adl:entity' on which the properties for all those fields can be found -->
		<xsl:param name="entity"/>
		<!-- the name of the list of instances of this entity, available to Velocity at runtime 
				as an ICollection, which is to be layed out in this list -->
		<xsl:param name="instance-list" select="'instances'"/>
		<!-- NOTE NOTE NOTE: To be searchable, internal-with-properties-list must not only be called with can-search
			equal to 'true', but also within a form! -->
		<!-- NOTE NOTE NOTE: It's obvious that internal-with-fields-list and internal-with-properties-list
			ought to be replaced with a single template, but that template proves to be extremely hard to get 
			right -->
		<xsl:param name="can-search"/>
		<table>
			<tr>
				<xsl:for-each select="$properties">
					<th>
						<xsl:call-template name="showprompt">
							<xsl:with-param name="node" select="."/>
							<xsl:with-param name="fallback" select="@name"/>
							<xsl:with-param name="entity" select="$entity"/>
							<xsl:with-param name="locale" select="$locale"/>
						</xsl:call-template>
					</th>
				</xsl:for-each>
				<xsl:for-each select="$entity/adl:form">
					<th>-</th>
				</xsl:for-each>
			</tr>
			<xsl:if test="$can-search = 'true'">
				<tr class="search">
					<xsl:for-each select="$properties">
						<td class="search">
							<xsl:variable name="size">
								<xsl:choose>
									<xsl:when test="@type='string'">
										<xsl:choose>
											<xsl:when test="@size &gt; 20">20</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@size"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@type='integer'">8</xsl:when>
									<xsl:when test="@type='real'">8</xsl:when>
									<xsl:when test="@type='money'">8</xsl:when>
									<!-- xsl:when test="@type='message'">20</xsl:when doesn't work yet -->
									<xsl:when test="@type='text'">20</xsl:when>
									<!-- xsl:when test="@type='enity'">20</xsl:when doesn't work yet -->
									<xsl:otherwise>0</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:if test="$size != 0">
								<input>
									<xsl:attribute name="name">
										<xsl:value-of select="concat('search_', @name)"/>
									</xsl:attribute>
									<xsl:attribute name="size">
										<xsl:value-of select="$size"/>
									</xsl:attribute>
									<xsl:attribute name="value">
										<xsl:value-of select="concat( '$!search_', @name)"/>
									</xsl:attribute>
								</input>
							</xsl:if>
						</td>
					</xsl:for-each>
					<td>
						<input type="submit" name="search-button" value="Search!"/>
					</td>
				</tr>
			</xsl:if>
			#foreach( <xsl:value-of select="concat( '$', $entity/@name)"/> in <xsl:value-of select="concat('$', $instance-list)"/>)
			#if ( $velocityCount % 2 == 0)
			#set( $oddity = "even")
			#else
			#set( $oddity = "odd")
			#end
			<tr class="$oddity">
				<xsl:for-each select="$properties">
					<xsl:call-template name="list-field">
						<xsl:with-param name="entity" select="$entity"/>
						<xsl:with-param name="property" select="."/>
						<xsl:with-param name="objectvar" select="$entity/@name"/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:variable name="keys">
					<!-- assemble keys in a Velocity-friendly format, then splice it into
                    the HREF below -->
					<xsl:for-each select="$entity/adl:key/adl:property">
						<xsl:variable name="sep">
							<xsl:choose>
								<xsl:when test="position()=1">?</xsl:when>
								<xsl:otherwise>&amp;</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="@type='entity'">
								<xsl:value-of select="concat( $sep, @name, '=$', $entity/@name, '.', @name, '_Value')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat( $sep, @name, '=$', $entity/@name, '.', @name)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:for-each select="$entity/adl:form">
					<!-- by default create a link to each form declared for the entity. 
                    We probably need a means of overriding this -->
					<td>
						<a>
							<xsl:attribute name="href">
								<xsl:value-of select="concat( '../', $entity/@name, '/', @name, '.rails', $keys)"/>
							</xsl:attribute>
							<xsl:value-of select="@name"/>!
						</a>
					</td>
				</xsl:for-each>
			</tr>
			#end
		</table>
	</xsl:template>

	<!-- output a list field -->
	<xsl:template name="list-field">
		<xsl:param name="entity"/>
		<xsl:param name="property"/>
		<xsl:param name="objectvar" select="instance"/>
		<xsl:variable name="readgroups">
			<xsl:call-template name="property-read-groups">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
		<td>
			<xsl:choose>
				<xsl:when test="$authentication-layer = 'Application'">
					<xsl:call-template name="list-field-inner">
						<xsl:with-param name="entity" select="$entity"/>
						<xsl:with-param name="property" select="$property"/>
						<xsl:with-param name="objectvar" select="$objectvar"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$authentication-layer = 'Database'">
					<!-- NOTE NOTE NOTE: This is whitespace-sensitive! -->
					#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
					<xsl:if test="$property/@type='entity'">
						<!-- right, this is horrible. You can't read the field unless you can read the property; 
						but even if you can read the property, if its an entity property you still can't read it
						unless you can also read the entity -->
						<xsl:variable name="entityreadgroups">
							<xsl:call-template name="entity-read-groups">
								<xsl:with-param name="entity" select="//adl:entity[@name=$property/@entity]"/>
							</xsl:call-template>
						</xsl:variable>
						#if ( <xsl:for-each select="exsl:node-set( $entityreadgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
					</xsl:if>
					<xsl:call-template name="list-field-inner">
						<xsl:with-param name="entity" select="$entity"/>
						<xsl:with-param name="property" select="$property"/>
						<xsl:with-param name="objectvar" select="$objectvar"/>
					</xsl:call-template>
					<xsl:if test="$property/@type='entity'">
						#else
						[Not authorised]
						#end
					</xsl:if>
					#else
					[Not authorised]
					#end
				</xsl:when>
			</xsl:choose>
		</td>
	</xsl:template>

	<xsl:template name="list-field-inner">
		<xsl:param name="entity"/>
		<xsl:param name="property"/>
		<xsl:param name="objectvar" select="instance"/>
		<xsl:choose>
			<xsl:when test="$property/adl:option">
				<xsl:for-each select="$property/adl:option">
					<xsl:variable name="val">
						<xsl:variable name="base-type">
							<xsl:call-template name="base-type">
								<xsl:with-param name="property" select="$property"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="$base-type = 'string'">
								<xsl:value-of select="concat( '&#34;', @value, '&#34;')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="@value"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					#if( <xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/> == <xsl:value-of select="$val"/>)
					<xsl:call-template name="showprompt">
						<xsl:with-param name="node" select="."/>
						<xsl:with-param name="fallback" select="@value"/>
					</xsl:call-template>
					#end
				</xsl:for-each>
			</xsl:when> 
			<xsl:when test="$property/@type = 'date'">
				#if ( <xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/>)
				<xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/>.ToString( 'd')
				#end
			</xsl:when>
			<xsl:when test="$property/@type='message'">
				#if ( <xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/>)
				$t.Msg( <xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/>)
				#end
			</xsl:when>
			<xsl:when test="$property/@type='entity'">
				#if( <xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name)"/>)
				<xsl:value-of select="concat( '$', $entity/@name, '.', $property/@name, '.UserIdentifier')"/>
				#end
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat( '$!', $entity/@name, '.', $property/@name)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- generate head javascript for a form -->
	<xsl:template name="generate-head-javascript">
		<xsl:param name="form">
			<!-- assumed to be an instance of adl:form -->
		</xsl:param>
		<script type='text/javascript' language='JavaScript1.2'>
			#if ( ${site-root})
			var siteRoot = '$siteRoot';
			#else
			var siteRoot = '<xsl:value-of select='$site-root'/>';
			#end

			function performInitialisation()
			{
			<xsl:for-each select="$form/ancestor::adl:entity/adl:property[@type='link']">
				<xsl:variable name="propname" select="@name"/>
				<xsl:choose>
					<xsl:when test="$form/@properties='all'">
						document.<xsl:value-of select="$form/@name"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
					</xsl:when>
					<xsl:when test="$form//adl:field[@property=$propname]">
						document.<xsl:value-of select="$form/@name"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
					</xsl:when>
					<!-- if we're not doing all properties, and if this property is not the property of a field,
						we /don't/ set up a submit handler. -->
				</xsl:choose>
			</xsl:for-each>
			var validator = new Validation('<xsl:value-of select="$form/@name"/>', {immediate : true, useTitles : true});
			}

			<xsl:for-each select="//adl:typedef">
				<xsl:variable name="errormsg">
					<xsl:choose>
						<xsl:when test="adl:help[@locale=$locale]">
							<xsl:apply-templates select="adl:help[@locale=$locale]"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="i18n-bad-format">
								<xsl:with-param name="format-name" select="@name"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				Validation.add( '<xsl:value-of select="concat('validate-custom-', @name)"/>',
				'<xsl:value-of select="normalize-space( $errormsg)"/>',
				{
				<xsl:choose>
					<xsl:when test="@pattern">
						pattern : new RegExp("<xsl:value-of select="@pattern"/>","gi")<xsl:if test="@size">
							, maxLength : <xsl:value-of select="@size"/>
						</xsl:if>
					</xsl:when>
					<xsl:when test="@minimum">
						min : <xsl:value-of select="@minimum"/><xsl:if test="@maximum">
							, max : <xsl:value-of select="@maximum"/>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
				});
			</xsl:for-each>
		</script>
	</xsl:template>

	<!-- this template outputs MOST types of widget, but NOT shuffle widgets -->
	<xsl:template name="property-widget">
		<xsl:param name="property"/>
		<xsl:param name="mode"/>
		<xsl:variable name="base-type">
			<xsl:call-template name="base-type">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="href">
			<xsl:choose>
				<xsl:when test="$property/@type='entity' and //adl:entity[@name=$property/@entity]/adl:form[@name='edit']">
					<!-- if this is an entity property, and the entity which it wraps has an edit form -->
					<xsl:variable name="keys">
						<xsl:call-template name="entity-keys-fragment">
							<xsl:with-param name="entity" select="//adl:entity[@name=$property/@entity]"/>
							<xsl:with-param name="instance" select="concat( 'instance.', $property/@name)"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="concat( '../', $property/@entity, '/edit.rails', $keys)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="if-missing">
			<xsl:choose>
				<xsl:when test="$property/adl:if-missing[@locale = $locale]">
					<xsl:value-of select="$property/adl:if-missing[@locale = $locale]"/>
				</xsl:when>
				<xsl:when test="$property/@required='true'">
					<xsl:call-template name="i18n-value-required">
						<xsl:with-param name="property-name" select="$property/@name"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$property/@type='defined'">
					<xsl:call-template name="i18n-value-defined">
						<xsl:with-param name="property-name" select="$property/@name"/>
						<xsl:with-param name="definition-name" select="$property/@typedef"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$property/@type='entity'">
					<xsl:call-template name="i18n-value-entity">
						<xsl:with-param name="property-name" select="$property/@name"/>
						<xsl:with-param name="entity-name" select="$property/@entity"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="i18n-value-type">
						<xsl:with-param name="property-name" select="$property/@name"/>
						<xsl:with-param name="type-name" select="$property/@type"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="cssclass">
			<xsl:if test="$property/@required='true'">required </xsl:if>
			<xsl:choose>
				<xsl:when test="$property/@type='defined'">
					<xsl:choose>
						<xsl:when test="//adl:typedef[@name=$property/@typedef]/@pattern">
							<xsl:value-of select="concat( 'validate-custom-', $property/@typedef)"/>
						</xsl:when>
						<xsl:when test="//adl:typedef[@name=$property/@typedef]/@minimum">
							<xsl:value-of select="concat( 'validate-custom-', $property/@typedef)"/>
						</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$base-type='integer'">validate-digits</xsl:when>
				<xsl:when test="$base-type='real'">validate-number</xsl:when>
				<xsl:when test="$base-type='money'">validate-number</xsl:when>
				<xsl:when test="$base-type='date'">date-field validate-date</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="maxlength">
			<xsl:call-template name="base-size">
				<xsl:with-param name="property" select="$property"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="size">
			<xsl:choose>
				<xsl:when test="$maxlength &gt; $max-widget-width">
					<xsl:value-of select="$max-widget-width"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$maxlength"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="rows">
			<!-- number of rows, if textarea emitted -->
			<xsl:choose>
				<xsl:when test="$base-type = 'text'">8</xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="cols">
			<!-- number of rows, if textarea emitted -->
			<xsl:choose>
				<xsl:when test="$base-type = 'text'">
					<xsl:value-of select="$max-widget-width"/>
				</xsl:when>
				<xsl:otherwise>10</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="required">
			<xsl:choose>
				<xsl:when test="$property/@required='true'">true</xsl:when>
				<xsl:otherwise>false</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$property/adl:option">
				<!-- emit a menu of options -->
				<!-- it would be better to do this through a field helper but I haven't yet worked out how -->
				<select>
					<xsl:attribute name="name">
						<xsl:value-of select="concat( 'instance.', $property/@name)"/>
					</xsl:attribute>
					<xsl:attribute name="id">
						<xsl:value-of select="concat( 'instance_', $property/@name)"/>
					</xsl:attribute>
					<xsl:attribute name="class">
						<xsl:value-of select="concat( 'instance.', $property/@name)"/>
					</xsl:attribute>
					<xsl:if test="not( $property/@required='true')">
						<option value="'-1'">[unselected]</option>
					</xsl:if>
					<xsl:apply-templates select="$property/adl:option"/>
				</select>
				<script type="text/javascript" language="javascript">
					// &lt;![CDATA[
					#set ( <xsl:value-of select="concat( '$', $property/@name, '_sel_opt')"/>="<xsl:value-of select="concat( $property/@name, '-$instance.', $property/@name)"/>")
					option = document.getElementById( "<xsl:value-of select="concat( '$', $property/@name, '_sel_opt')"/>");

					if ( option != null)
					{
					option.selected = true;
					}
					// ]]&gt;
				</script>

			</xsl:when>
			<xsl:when test="$property/@type = 'defined'">
				<!-- it would be better to do this through a field helper but I haven't yet worked out how -->
				<xsl:variable name="definition" select="//adl:typedef[@name=$property/@typedef]"/>
				<xsl:variable name="minimum" select="$definition/@minimum"/>
				<xsl:choose>
					<xsl:when test="$base-type='string'">
						${<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, 'FieldHelper', '.', $mode, '(')"/> "<xsl:value-of select="concat( 'instance.', $property/@name)"/>", "%{class='<xsl:value-of select="normalize-space($cssclass)"/>',required='<xsl:value-of select="normalize-space( $required)"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>',href='<xsl:value-of select="normalize-space($href)"/>'}")}
					</xsl:when>
					<xsl:when test="string-length($definition/@minimum) &gt; 0 and string-length( $definition/@maximum) &gt; 0">
						<xsl:call-template name="slider-widget">
							<xsl:with-param name="property" select="$property"/>
							<xsl:with-param name="minimum" select="$definition/@minimum"/>
							<xsl:with-param name="maximum" select="$definition/@maximum"/>
						</xsl:call-template>
						${<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, 'FieldHelper', '.', $mode, '(')"/> "<xsl:value-of select="concat( 'instance.', $property/@name)"/>", "%{class='<xsl:value-of select="concat('slider, ', normalize-space($cssclass))"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>',href='<xsl:value-of select="normalize-space($href)"/>'}")}
					</xsl:when>
					<xsl:otherwise>
						${<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, 'FieldHelper', '.', $mode, '(')"/> "<xsl:value-of select="concat( 'instance.', $property/@name)"/>", "%{class='<xsl:value-of select="normalize-space($cssclass)"/>',required='<xsl:value-of select="normalize-space( $required)"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>',href='<xsl:value-of select="normalize-space($href)"/>'}")}
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property/@type = 'entity'">
				<!-- once again, not only must you have access to the property but also to the entity -->
				<xsl:variable name="readgroups">
					<xsl:call-template name="entity-read-groups">
						<xsl:with-param name="entity" select="//adl:entity[@name=$property/@entity]"/>
					</xsl:call-template>
				</xsl:variable>
				<!-- NOTE! NOTE! NOTE! Whitespace is significant - any linefeeds inside the #if ( ) clause cause the Velocity parser to break! -->
				#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
				${<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, 'FieldHelper', '.', $mode, '(')"/> "<xsl:value-of select="concat( 'instance.', $property/@name)"/>", "%{class='<xsl:value-of select="normalize-space($cssclass)"/>',required='<xsl:value-of select="normalize-space( $required)"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>',href='<xsl:value-of select="normalize-space($href)"/>'}")}
				#else
				[Not authorised]
				#end
			</xsl:when>
			<xsl:otherwise>
				${<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, 'FieldHelper', '.', $mode, '(')"/> "<xsl:value-of select="concat( 'instance.', $property/@name)"/>", "%{class='<xsl:value-of select="normalize-space($cssclass)"/>',required='<xsl:value-of select="normalize-space( $required)"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>',cols='<xsl:value-of select="normalize-space($cols)"/>',href='<xsl:value-of select="normalize-space($href)"/>'}")}
      </xsl:otherwise>				
		</xsl:choose>
	</xsl:template>

	<xsl:template name="slider-widget">
		<xsl:param name="property"/>
		<xsl:param name="minimum" select="0"/>
		<xsl:param name="maximum" select="100"/>
		<xsl:if test="string-length( $minimum) &gt; 0 and string-length( $maximum) &gt; 0">
			<div style="width:200px; height:20px; background: transparent url(../images/slider-images-track-right.png) no-repeat top right;">
				<xsl:attribute name="id">
					<xsl:value-of select="concat( $property/@name, '-track')"/>
				</xsl:attribute>
				<div style="position: absolute; width: 5px; height: 20px; background: transparent url(../images/slider-images-track-left.png) no-repeat top left">
					<xsl:attribute name="id">
						<xsl:value-of select="concat( $property/@name, '-track-left')"/>
					</xsl:attribute>
				</div>
				<div style="width:19px; height:20px;">
					<xsl:attribute name="id">
						<xsl:value-of select="concat( $property/@name, '-slider')"/>
					</xsl:attribute>
					<img src="../images/slider-images-handle.png" alt="" style="float: left;" />
				</div>
			</div>
			<script type="text/javascript" language="javascript">
				// &lt;![CDATA[
				new Control.Slider('<xsl:value-of select="$property/@name"/>-slider','<xsl:value-of select="$property/@name"/>-track',{
				onSlide:function(v){$('<xsl:value-of select="concat( 'instance_', $property/@name)"/>').value = <xsl:value-of select="$minimum"/>+ Math.floor(v*(<xsl:value-of select="$maximum - $minimum"/>))}
        });
        // ]]&gt;
			</script>
		</xsl:if>
	</xsl:template>

	<!-- assemble keys for this entity in a Velocity-friendly format, to splice into an HREF below -->
	<xsl:template name="entity-keys-fragment">
		<xsl:param name="entity"/>
		<xsl:param name="instance" select="$entity/@name"/>
		<xsl:for-each select="$entity/adl:key/adl:property">
			<xsl:variable name="sep">
				<xsl:choose>
					<xsl:when test="position()=1">?</xsl:when>
					<xsl:otherwise>&amp;</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="@type='entity'">
					<xsl:value-of select="concat( $sep, @name, '=$', $instance, '.', @name, '_Value')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat( $sep, @name, '=$', $instance, '.', @name)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- overall page layout -->

	<xsl:template match="adl:content"/>

	<xsl:template match="adl:help">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- assuming an empty layout, install all the standard scripts 
    which an ADL page may need -->
	<xsl:template name="install-scripts">
		${ScriptsHelper.InstallScript( "ShuffleWidget")}

		${Ajax.InstallScripts()}
		${FormHelper.InstallScripts()}
		${Validation.InstallScripts()}
		${Scriptaculous.InstallScripts()}
		${DateTimeHelper.InstallScripts()}

		${ScriptsHelper.InstallScript( "Sitewide")}
		${ScriptsHelper.InstallScript( "Behaviour")}
		${ScriptsHelper.InstallScript( "Epoch")}
		${ScriptsHelper.InstallScript( "Panes")}
	</xsl:template>

	<xsl:template name="head">
    <xsl:choose>
      <xsl:when test="adl:head">
        <xsl:for-each select="adl:head/*">
          <xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:head/*">
					<xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="top">
    <xsl:choose>
      <xsl:when test="adl:top">
        <xsl:for-each select="adl:top/*">
					<xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:top/*">
					<xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
	<xsl:if test="$generate-site-navigation = 'true'">
      <ul class="generatednav">
        <xsl:for-each select="//adl:entity[adl:list[@name='list']]">
			<xsl:variable name="readgroups">
				<xsl:call-template name="page-read-groups">
					<xsl:with-param name="page" select="."/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$authentication-layer = 'Database'">
				#if ( <xsl:for-each select="exsl:node-set( $readgroups)/*">${SecurityHelper.InGroup( "<xsl:value-of select="./@name"/>")} ||</xsl:for-each> false)
			</xsl:if>
			<li class="navigation">
				<a>
					<xsl:attribute name="href">
						<xsl:choose>
							<xsl:when test="string-length( $site-root) &gt; 0">
								<xsl:choose>
									<xsl:when test="string-length( $area-name) &gt; 0">
										<xsl:value-of select="concat( $site-root, '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat( $site-root, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="string-length( $area-name) &gt; 0">
								<xsl:value-of select="concat( '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat( '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:value-of select="@name"/>
				</a>
			</li>
			<xsl:if test="$authentication-layer != 'Application'">
				#end
			</xsl:if>
        </xsl:for-each>
      </ul>
    </xsl:if>
  </xsl:template>

  <xsl:template name="foot">
    <xsl:choose>
      <xsl:when test="adl:foot">
        <xsl:for-each select="adl:foot/*">
					<xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:foot/*">
					<xsl:apply-templates select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
	  <p class="product-version">
		  <xsl:value-of select="$product-version"/>; built with <xsl:value-of select="$authentication-layer"/>-layer authentication.
	  </p>
  </xsl:template>

	<!-- if this node (default to current node) has a child of type prompt for the current locale, 
    show that prompt; else show the first prompt child with locale='default' if any;
    else show the value of the fallback param -->
	<xsl:template name="showprompt">
		<xsl:param name="fallback" select="'Unknown'"/>
		<xsl:param name="node" select="."/>
		<xsl:param name="entity" select="$node/ancestor::adl:entity"/>
		<xsl:param name="locale" select="'en-GB'"/>
		<xsl:choose>
			<xsl:when test="$node/adl:prompt[@locale=$locale]">
				<xsl:value-of select="$node/adl:prompt[@locale=$locale][1]/@prompt"/>
			</xsl:when>
			<xsl:when test="$node/adl:prompt[@locale='default']">
				<xsl:value-of select="$node/adl:prompt[@locale='default'][1]/@prompt"/>
			</xsl:when>
			<xsl:when test="$node/@property">
				<!-- it's (probably) a field which doesn't have any prompt of its own - 
					fetch from its property -->
				<xsl:variable name="propname" select="@property"/>
				<xsl:call-template name="showprompt">
					<xsl:with-param name="fallback" select="$fallback"/>
					<xsl:with-param name="node" select="$entity//adl:property[@name=$propname]"/>
					<xsl:with-param name="entity" select="$entity"/>
					<xsl:with-param name="locale" select="$locale"/>
				</xsl:call-template>
			</xsl:when>	  
			<xsl:otherwise>
				<xsl:value-of select="$fallback"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="groups">
		<xsl:apply-templates/>
	</xsl:template>

    <!-- just copy anything we can't match -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>