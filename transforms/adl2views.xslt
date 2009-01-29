<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
	xmlns="http://libs.cygnets.co.uk/adl/1.1/"
	xmlns:adl="http://libs.cygnets.co.uk/adl/1.1/"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt">
	<!--
    Application Description Language framework
    adl2views.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into velocity view templates
    
    $Author: sb $
    $Revision: 1.19 $
    $Date: 2009-01-29 16:39:32 $
	-->
	<!-- WARNING WARNING WARNING: Do NOT reformat this file! 
		Whitespace (or lack of it) is significant! -->

	<xsl:include href="base-type-include.xslt"/>

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


	<!-- the current state of play is that we can only generate views with permissions for one group. 
		TODO: this isn't how it's supposed to be. It's supposed to be that at service time the system 
		checks which groups the current user is member of, and renders each widget with the most relaxed 
		permissions applicable to that user - but we don't yet have the parts in place to do that.
		This variable selects which group's permissions should be used when generating widgets -->
	<xsl:param name="permissions-group" select="'public'"/>

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

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>
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

						Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>

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
		<xsl:variable name="formname" select="@name"/>
		<xsl:text>
		</xsl:text>
		<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( ancestor::adl:entity/@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
		<xsl:text>
      </xsl:text>
		<xsl:comment>
			<xsl:value-of select="$product-version"/>

			Auto generated Velocity <xsl:value-of select="@name"/> form for <xsl:value-of select="ancestor::adl:entity/@name"/>,
			generated from ADL.

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>

			<xsl:value-of select="/adl:application/@revision"/>
		</xsl:comment>
		#capturefor( title)
		#if ( $instance)
		<xsl:value-of select="concat( 'Edit ', ' ', ancestor::adl:entity/@name)"/> $instance.UserIdentifier
		#else
		<xsl:call-template name="i18n-add-a-new">
			<xsl:with-param name="entity-name" select="ancestor::adl:entity/@name"/>
		</xsl:call-template>
		#end
		#end
		#capturefor( headextras)
		<xsl:call-template name="head"/>
		<script type='text/javascript' language='JavaScript1.2'>
			var siteRoot = '$siteRoot';

			function performInitialisation()
			{
			<xsl:for-each select="ancestor::adl:entity/adl:property[@type='link' or @type='list']">
				<xsl:variable name="propname" select="@name"/>
				<xsl:choose>
					<xsl:when test="not( @properties='listed')">
				document.<xsl:value-of select="$formname"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
					</xsl:when>
					<xsl:when test=".//field[@property=$propname]">
				document.<xsl:value-of select="$formname"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
					</xsl:when>
					<!-- if we're not doing all properties, and if this property is not the property of a field,
						we /don't/ set up a submit handler. -->
				</xsl:choose>
			</xsl:for-each>
			<xsl:if test="adl:fieldgroup">
				switchtab( '<xsl:value-of select="adl:fieldgroup[1]/@name"/>');
			</xsl:if>
			}
			var validator = new Validation('<xsl:value-of select="$formname"/>', {immediate : true, useTitles : true});

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
							,
							maxLength : <xsl:value-of select="@size"/>
						</xsl:if>
					</xsl:when>
					<xsl:when test="@minimum">
						min : <xsl:value-of select="@minimum"/><xsl:if test="@maximum">
							,
							max : <xsl:value-of select="@maximum"/>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
				});
			</xsl:for-each>

		</script>

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
		<xsl:variable name="formname" select="@name"/>
		<xsl:text>
		</xsl:text>
		<xsl:comment>[ cut here: next file '<xsl:value-of select="concat( ancestor::adl:entity/@name, '/', @name)"/>.auto.vm' ]</xsl:comment>
		<xsl:text>
		</xsl:text>
		<html>
			<xsl:comment>
				#if ( $instance)
				#set( $title = "<xsl:value-of select="concat( 'Edit ', ' ', ancestor::adl:entity/@name)"/> $instance.UserIdentifier")
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

					Generated using adl2views.xsl <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>

					<xsl:value-of select="/adl:application/@revision"/>
				</xsl:comment>
				<xsl:call-template name="install-scripts"/>
				<script type='text/javascript' language='JavaScript1.2'>

					var siteRoot = '$siteRoot';

					function performInitialisation()
					{
					<xsl:for-each select="ancestor::adl:entity/adl:property[@type='link' or @type='list']">
						document.<xsl:value-of select="$formname"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
					</xsl:for-each>
						var validator = new Validation('<xsl:value-of select="$formname"/>', {immediate : true, useTitles : true});
					<xsl:if test="adl:fieldgroup">
						switchtab( '<xsl:value-of select="adl:fieldgroup[1]/@name"/>');
					</xsl:if>
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
									,
									maxLength : <xsl:value-of select="@size"/>
								</xsl:if>
							</xsl:when>
							<xsl:when test="@minimum">
								min : <xsl:value-of select="@minimum"/><xsl:if test="@maximum">
									,
									max : <xsl:value-of select="@maximum"/>
								</xsl:if>
							</xsl:when>
						</xsl:choose>
						});
					</xsl:for-each>

				</script>

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
		<xsl:variable name="formname" select="$form/@name"/>
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
					<xsl:value-of select="concat( $formname, 'SubmitHandler.rails')"/>
				</xsl:attribute>
				<xsl:attribute name="name">
					<xsl:value-of select="$formname"/>
				</xsl:attribute>
				<xsl:attribute name="id">
					<xsl:value-of select="$formname"/>
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
						<tr class="actionSafe">
							<td class="actionSafe" colspan="2">
								<xsl:call-template name='i18n-save-prompt'/>
							</td>
							<td class="actionSafe" style="text-align:right">
								<button type="submit" name="command" value="store">Save this!</button>
							</td>
						</tr>
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
					</table>
				</div>
			</form>
		</div>
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

		<td>
			<xsl:attribute name="colspan">
				<xsl:value-of select="count( field)"/>
			</xsl:attribute>

			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<xsl:comment>auxlist for with listed fields: <xsl:value-of select="$farent/@name"/></xsl:comment>
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
	</xsl:template>

	<xsl:template match="adl:verb">
		<xsl:variable name="class">
			<xsl:choose>
				<xsl:when test="@dangerous='true'">actionDangerous</xsl:when>
				<xsl:otherwise>actionSafe</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
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
		<!-- TODO: Permissions! -->
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
				<table class="shuffle">
					<tr>
						<td class="widget shuffle-all" rowspan="2">
							${ShuffleWidgetHelper.UnselectedOptions( "<xsl:value-of select="concat( @name, '_unselected')"/>", <xsl:value-of select="concat( '$all_', @name)"/>, $instance.<xsl:value-of select="@name"/>)}
						</td>
						<td class="widget shuffle-action">
							<input type="button" value="include &gt;&gt;">
								<xsl:attribute name="onclick">
									<xsl:value-of select="concat( 'shuffle(', @name, '_unselected, ', @name, ')')"/>
								</xsl:attribute>
							</input>
						</td>
						<td class="widget shuffle-selected" rowspan="2">
							<xsl:variable name="entityname" select="@entity"/>
							<xsl:variable name="foreignkey" select="@farkey"/>
							<xsl:variable name="allow-shuffle-back">
								<xsl:choose>
									<xsl:when test="@type='list' and //adl:entity[@name=$entityname]//adl:property[@name=$foreignkey and @required='true']"> 
										<xsl:value-of select="'false'"/> 
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="'true'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							${ShuffleWidgetHelper.SelectedOptions( "<xsl:value-of select="@name"/>", $instance.<xsl:value-of select="@name"/>, <xsl:value-of select="$allow-shuffle-back"/>)}
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

	<xsl:template match="adl:property">
		<xsl:param name="oddness" select="odd"/>
		<!-- note! this template is only intended to match properties in the context of a form:
			it may be we need to add a mode to indicate this! -->
		<!-- TODO: we really need to be able to handle different permissions for different 
			groups. If the current user is not a member of a group which has read access to 
			this widget, the widget shouldn't even appear (unless they have write but not read?); 
			if they are not a member of a group which has write access, the widget should be 
			disabled. I don't have time to implement this now as it is not trivial, but it is 
			important! -->
		<xsl:message terminate="no">
			matched adl:property; groupname is '<xsl:value-of select="$permissions-group"/>'
		</xsl:message>
		<xsl:variable name="permission">
			<xsl:call-template name="property-permission">
				<xsl:with-param name="property" select="."/>
				<xsl:with-param name="groupname" select="$permissions-group"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:message terminate="no">
			matched adl:property; parmission = '<xsl:value-of select="$permission"/>'
		</xsl:message>
		<xsl:if test="$permission != 'none'">
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
					<xsl:variable name="render-mode">
						<xsl:choose>
							<xsl:when test="$permission='all'">edit</xsl:when>
							<xsl:when test="$permission='edit'">edit</xsl:when>
							<xsl:when test="$permission='noedit'">$maybe-edit</xsl:when>
							<xsl:when test="$permission='insert'">$maybe-edit</xsl:when>
							<xsl:when test="$permission='read'">noneditable</xsl:when>
							<xsl:otherwise>none</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="if-missing">
						<xsl:choose>
							<xsl:when test="adl:if-missing[@locale = $locale]">
								<xsl:value-of select="adl:if-missing[@locale = $locale]"/>
							</xsl:when>
							<xsl:when test="@required='true'">
								<xsl:call-template name="i18n-value-required">
									<xsl:with-param name="propert-name" select="@name"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:when test="@type='defined'">
								<xsl:call-template name="i18n-value-defined">
									<xsl:with-param name="property-name" select="@name"/>
									<xsl:with-param name="definition-name" select="@typedef"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:when test="@type='entity'">
								<xsl:call-template name="i18n-value-entity">
									<xsl:with-param name="property-name" select="@name"/>
									<xsl:with-param name="entity-name" select="@entity"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="i18n-value-type">
									<xsl:with-param name="property-name" select="@name"/>
									<xsl:with-param name="type-name" select="@type"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="definition" select="@typedef"/>
					<xsl:variable name="definedtype" select="//adl:typedef[@name=$definition]/@type"/>
					<xsl:variable name="base-type">
						<xsl:call-template name="base-type">
							<xsl:with-param name="property" select="."/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="cssclass">
						<xsl:if test="@required='true'">required </xsl:if>
						<xsl:choose>
							<xsl:when test="@type='defined'">
								<xsl:choose>
									<xsl:when test="//adl:typedef[@name=$definition]/@pattern">
										<xsl:value-of select="concat( 'validate-custom-', $definition)"/>
									</xsl:when>
									<xsl:when test="//adl:typedef[@name=$definition]/@minimum">
										<xsl:value-of select="concat( 'validate-custom-', $definition)"/>
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
							<xsl:with-param name="property" select="."/>
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
						<xsl:choose>
							<xsl:when test="$base-type = 'text'">8</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$permission='insert' or $permission='noedit'">
						#set ( $maybe-edit="editable")
						#if ( $instance)
						#if ( <xsl:value-of select="concat( '$instance.', @name)"/>)
						<xsl:choose>
							<xsl:when test="$permission='insert'">
								#set ( $maybe-edit="none")
							</xsl:when>
							<xsl:when test="$permission='noedit'">
								#set ( $maybe-edit="noneditable")
							</xsl:when>
						</xsl:choose>
						#set( $maybe-edit="editable")
						#end
						#end
					</xsl:if>
					${<xsl:value-of select="concat( ancestor::adl:entity/@name, 'FieldHelper')"/>.Editable( "<xsl:value-of select="concat( 'instance.', @name)"/>", "%{rendermode='<xsl:value-of select="normalize-space($render-mode)"/>',class='<xsl:value-of select="normalize-space($cssclass)"/>',title='<xsl:value-of select="normalize-space($if-missing)"/>',size='<xsl:value-of select="normalize-space($size)"/>',maxlength='<xsl:value-of select="normalize-space($maxlength)"/>',rows='<xsl:value-of select="normalize-space($rows)"/>'}")}
				</td>
				<td class="help">
					<xsl:apply-templates select="adl:help[@locale = $locale]"/>
				</td>
			</tr>
		</xsl:if>
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

			Generated using adl2views.xslt <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>
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

					  Generated using adl2listview.xsl <xsl:value-of select="substring( '$Revision: 1.19 $', 10)"/>
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
				  </tr>
			  </xsl:if>
			  <xsl:if test="not( $entity/@name)">
				  <xsl:message terminate="yes">
					  Unknown entity whilst trying to generate list
				  </xsl:message>
			  </xsl:if>
			  #foreach( <xsl:value-of select="concat( '$', $entity/@name)"/> in <xsl:value-of select="concat('$', $instance-list)"/>)
			  #if ( $velocityCount % 2 == 0)
			  #set( $oddity = "even")
			  #else
			  #set( $oddity = "odd")
			  #end
			  <tr class="$oddity">
				  <xsl:for-each select="$fields">
					  <xsl:variable name="field" select="."/>
					  <td>
						  <xsl:choose>
							  <xsl:when test="not( $entity//adl:property[@name=$field/@property]/@name)">
								  <!-- shouldn't happen. There is definitely a bug here, because it does happen - but it shouldn't -->
							  </xsl:when>
							  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type = 'date'">
								  #if ( <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>)
								  <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>.ToString( 'd')
								  #end
							  </xsl:when>
							  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='message'">
								  #if ( <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>)
								  $t.Msg( <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>)
								  #end
							  </xsl:when>
							  <xsl:when test="$entity//adl:property[@name=$field/@property]/@type='entity'">
								  #if( <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>)
								  <xsl:value-of select="concat( '$', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name, '.UserIdentifier')"/>
								  #end
							  </xsl:when>
							  <xsl:otherwise>
								  <xsl:value-of select="concat( '$!', $entity/@name, '.', $entity//adl:property[@name=$field/@property]/@name)"/>
							  </xsl:otherwise>
						  </xsl:choose>
					  </td>
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
					<td>
						<xsl:choose>
							<xsl:when test="@type = 'date'">
								#if ( <xsl:value-of select="concat( '$', $entity/@name, '.', @name)"/>)
								<xsl:value-of select="concat( '$', $entity/@name, '.', @name)"/>.ToString( 'd')
								#end
							</xsl:when>
							<xsl:when test="@type='message'">
								#if ( <xsl:value-of select="concat( '$', $entity/@name, '.', @name)"/>)
								$t.Msg( <xsl:value-of select="concat( '$', $entity/@name, '.', @name)"/>)
								#end
							</xsl:when>
							<xsl:when test="@type='entity'">
								#if( <xsl:value-of select="concat( '$', $entity/@name, '.', @name)"/>)
								<xsl:value-of select="concat( '$', $entity/@name, '.', @name, '.UserIdentifier')"/>
								#end
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat( '$!', $entity/@name, '.', @name)"/>
							</xsl:otherwise>
						</xsl:choose>
					</td>
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


	<!-- overall page layout -->

	<xsl:template match="adl:content"/>

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

	<xsl:template match="adl:navigation">
		<xsl:variable name="pagename" select="@name"/>
		<ul class="generatednav">
			<xsl:choose>
				<xsl:when test="@include='list'">
					<xsl:for-each select="//adl:entity[adl:list[@name=$pagename]]">
						<li>
							<a>
								<xsl:attribute name="href">
									<xsl:value-of select="concat( '$siteRoot', '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
								</xsl:attribute>
								<xsl:value-of select="@name"/>
							</a>
						</li>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="@include='form'">
					<xsl:for-each select="//adl:entity[adl:form[@name=$pagename]]">
						<li>
							<a>
								<xsl:attribute name="href">
									<xsl:value-of select="concat( '$siteRoot', '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
								</xsl:attribute>
								<xsl:value-of select="@name"/>
							</a>
						</li>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="@include='page'">
					<xsl:for-each select="//adl:entity[adl:page[@name=$pagename]]">
						<li>
							<a>
								<xsl:attribute name="href">
									<xsl:value-of select="concat( '$siteRoot', '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
								</xsl:attribute>
								<xsl:value-of select="@name"/>
							</a>
						</li>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>
		</ul>
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
          <li>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( '$siteRoot', '/', $area-name, '/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
              </xsl:attribute>
              <xsl:value-of select="@name"/>
            </a>
          </li>
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

	<!-- find, as a string, the permission which applies to this property in the context of the named group.
      NOTE: recurses up the group hierarchy - if it has cycles that's your problem, buster.
      property: a property element
      groupname: a string, being the name of a group
    -->
    <xsl:template name="property-permission">
      <xsl:param name="property"/>
      <xsl:param name="groupname" select="'public'"/>
		<xsl:message terminate="no">
			property-permission: property is '<xsl:value-of select="concat( $property/ancestor::adl:entity/@name, ':', $property/@name)"/>'; groupname is '<xsl:value-of select="$groupname"/>'
		</xsl:message>
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

    <!-- just copy anything we can't match -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>