<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
  xmlns="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output encoding="UTF-8" method="xml" indent="yes" />

	<xsl:param name="locale" select="en-GB"/>

	<xsl:param name="css-stylesheet"/>

	<xsl:param name="detail" select="full"/>

	<xsl:template match="adl:application">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title>
					Data definition for the <xsl:value-of select="@name"/> application
					version <xsl:value-of select="@version"/>
				</title>
				<xsl:if test="$css-stylesheet">
					<link rel="stylesheet" type="text/css">
						<xsl:attribute name="href">
							<xsl:value-of select="$css-stylesheet"/>
						</xsl:attribute>
					</link>
				</xsl:if>
			</head>
			<body>
				<a name="top"/>
				<h1>
					Data definition for the '<xsl:value-of select="@name"/>' application version <xsl:value-of select="@version"/>
				</h1>
				<xsl:if test="@revision">
					<p>
						<strong>
							Generated from <xsl:value-of select="substring( @revision, 2, string-length( @revision) - 2)"/> of the ADL specification.
						</strong>
					</p>
				</xsl:if>
				<xsl:apply-templates select="adl:documentation"/>
				<h2>Contents</h2>
				<dl>
					<xsl:for-each select="adl:entity">
						<dt>
							<a>
								<xsl:attribute name="href">
									<xsl:value-of select="concat( '#entity-', @name)"/>
								</xsl:attribute>
								<xsl:value-of select="@name"/>
							</a>
						</dt>
						<dd>
							<xsl:apply-templates select="adl:documentation"/>
						</dd>
					</xsl:for-each>
				</dl>
				<xsl:for-each select="adl:entity">
					<a>
						<xsl:attribute name="name">
							<xsl:value-of select="concat( 'entity-', @name)"/>
						</xsl:attribute>
					</a>
					<hr/>
					<h2>
						<xsl:value-of select="@name" />
					</h2>
					<xsl:apply-templates select="adl:documentation"/>
					<h3>Access control</h3>
					<table>
						<tr>
							<th>Group</th>
							<th>Permission</th>
						</tr>
						<xsl:for-each select="adl:permission">
							<tr>
								<td>
									<xsl:value-of select="@group"/>
								</td>
								<td>
									<xsl:value-of select="@permission"/>
								</td>
							</tr>
						</xsl:for-each>
					</table>
					<h3>Properties</h3>
					<table>
						<tr class="header">
							<th>Property</th>
							<th>Type</th>
							<xsl:if test="$detail = 'full'">
								<th>Req'd</th>
								<th>Def'lt</th>
								<th>Size</th>
								<th>Distinct</th>
								<th>Prompt</th>
							</xsl:if>
						</tr>
						<xsl:for-each select=".//adl:property" >
							<xsl:variable name="rowclass">
								<xsl:choose>
									<xsl:when test="position() mod 2 = 0">even</xsl:when>
									<xsl:otherwise>odd</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<tr>
								<xsl:attribute name="class">
									<xsl:value-of select="$rowclass"/>
								</xsl:attribute>
								<th>
									<xsl:value-of select="@name"/>&#160;
								</th>
								<td>
									<xsl:value-of select="@type"/>
									<xsl:choose>
										<xsl:when test="@type='entity'">
											of type <a>
												<xsl:attribute name="href">
													<xsl:value-of select="concat( '#entity-', @entity)"/>
												</xsl:attribute>
												<xsl:value-of select="@entity"/>
											</a>
										</xsl:when>
										<xsl:when test="@type = 'link'">
											(many to many) to entities of type <a>
												<xsl:attribute name="href">
													<xsl:value-of select="concat( '#entity-', @entity)"/>
												</xsl:attribute>
												<xsl:value-of select="@entity"/>
											</a>
										</xsl:when>
										<xsl:when test="@type = 'list'">
											(one to many) of entities of type <a>
												<xsl:attribute name="href">
													<xsl:value-of select="concat( '#entity-', @entity)"/>
												</xsl:attribute>
												<xsl:value-of select="@entity"/>
											</a>
										</xsl:when>
										<xsl:when test="@definition">
											:
											<xsl:variable name="definition">
												<xsl:value-of select="@definition"/>
											</xsl:variable>
											<xsl:variable name="defined-type">
												<xsl:value-of select="/adl:application/adl:definition[@name=$definition]/@type"/>
											</xsl:variable>
											<xsl:choose>
												<xsl:when  test="$defined-type = 'string'">
													String matching
													"<xsl:value-of select="/adl:application/adl:definition[@name=$definition]/@pattern"/>"
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="/adl:application/adl:definition[@name=$definition]/@minimum"/> &lt;
													<xsl:value-of select="@definition"/> &lt;
													<xsl:value-of select="/adl:application/adl:definition[@name=$definition]/@maximum"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
									</xsl:choose>
								</td>
								<xsl:if test="$detail = 'full'">
									<td>
										<xsl:value-of select="@required"/>&#160;
									</td>
									<td>
										<xsl:value-of select="@default"/>&#160;
									</td>
									<td>
										<xsl:value-of select="@size"/>&#160;
									</td>
									<td>
										<xsl:value-of select="@distinct"/>&#160;
									</td>
									<td>
										<xsl:for-each select="adl:prompt">
											<xsl:apply-templates select="adl:prompt"/>&#160;
										</xsl:for-each>
									</td>
								</xsl:if>
							</tr>
							<xsl:if test="adl:option">
								<tr>
									<xsl:attribute name="class">
										<xsl:value-of select="$rowclass"/>
									</xsl:attribute>
									<td>
										<xsl:attribute name="rowspan">
											<xsl:value-of select="count( adl:option)"/>
										</xsl:attribute>
										Options:
									</td>
									<td>
										<xsl:apply-templates select="adl:option[ position()=1]"/>
									</td>
									<xsl:for-each select="adl:option[position() &gt; 1]">
										<tr>
											<xsl:attribute name="class">
												<xsl:value-of select="$rowclass"/>
											</xsl:attribute>
											<td>
												<xsl:apply-templates select="."/>
											</td>
										</tr>
									</xsl:for-each>
								</tr>
							</xsl:if>
							<xsl:if test="adl:help">
								<tr>
									<xsl:attribute name="class">
										<xsl:value-of select="$rowclass"/>
									</xsl:attribute>
									<td>
										<td>Helptext:</td>
										<td>
											<xsl:attribute name="colspan">
												<xsl:choose>
													<xsl:when test="$detail='full'">7</xsl:when>
													<xsl:otherwise>2</xsl:otherwise>
												</xsl:choose>
											</xsl:attribute>
											<xsl:apply-templates select="adl:help"/>
										</td>
									</td>
								</tr>
							</xsl:if>
							<xsl:if test="adl:documentation">
								<tr>
									<xsl:attribute name="class">
										<xsl:value-of select="$rowclass"/>
									</xsl:attribute>
									<td>Documentation:</td>
									<td>
										<xsl:attribute name="colspan">
											<xsl:choose>
												<xsl:when test="$detail='full'">7</xsl:when>
												<xsl:otherwise>2</xsl:otherwise>
											</xsl:choose>
										</xsl:attribute>
										<xsl:apply-templates select="adl:documentation"/>
									</td>
								</tr>
							</xsl:if>
						</xsl:for-each>
					</table>
					<xsl:apply-templates select="form"/>
					<xsl:apply-templates select="list"/>
					<xsl:apply-templates select="page"/>
					<a href="#top">[back to top]</a>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="adl:prompt">
		<!-- If I'm the prompt for the current locale, show me; 
    if I'm the default prompt, show me only if there isn't 
    one for the default locale -->
		<xsl:choose>
			<xsl:when test="@locale=$locale">
				<xsl:value-of select="@prompt"/>
			</xsl:when>
			<xsl:when test="@locale='default'">
				<xsl:choose>
					<xsl:when test="../adl:prompt[@locale=$locale]"/>
					<xsl:otherwise>
						<xsl:value-of select="@prompt"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="adl:help">
		<!-- If I'm the helptext for the current locale, show me; 
    if I'm the default helptext, show me only if there isn't 
    one for the default locale -->
		<xsl:choose>
			<xsl:when test="@locale=$locale">
				<xsl:apply-templates/>
			</xsl:when>
			<xsl:when test="@locale='default'">
				<xsl:choose>
					<xsl:when test="../adl:help[@locale=$locale]"/>
					<xsl:otherwise>
						<xsl:apply-templates/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="adl:documentation">
		<div xmlns="http://www.w3.org/1999/xhtml" class="documentation">
			<xsl:apply-templates />
		</div>
	</xsl:template>

	<xsl:template match="adl:form">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<h3 xmlns="http://www.w3.org/1999/xhtml">
				Form <xsl:value-of select="@name"/>
			</h3>
			<xsl:if test="adl:permission">
				<h4 xmlns="http://www.w3.org/1999/xhtml">Permissions</h4>
				<ul xmlns="http://www.w3.org/1999/xhtml">
					<xsl:apply-templates select="permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table xmlns="http://www.w3.org/1999/xhtml">
						<tr>
							<th>&#160;</th>
							<th>Property</th>
							<th>Prompt</th>
							<th>Documentation</th>
						</tr>
						<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
					</table>
				</xsl:when>
				<xsl:otherwise>
					<p>Showing all properties</p>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

	<xsl:template match="adl:page">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<h3 xmlns="http://www.w3.org/1999/xhtml">
				Page <xsl:value-of select="@name"/>
			</h3>
			<xsl:if test="adl:permission">
				<ul xmlns="http://www.w3.org/1999/xhtml">
					<xsl:apply-templates select="permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table xmlns="http://www.w3.org/1999/xhtml">
						<tr>
							<th>&#160;</th>
							<th>Property</th>
							<th>Prompt</th>
							<th>Documentation</th>
						</tr>
						<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
					</table>
				</xsl:when>
				<xsl:otherwise>
					<p>Showing all properties</p>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

	<xsl:template match="adl:list">
		<div xmlns="http://www.w3.org/1999/xhtml">
			<h3 xmlns="http://www.w3.org/1999/xhtml">
				List <xsl:value-of select="@name"/>, on select <xsl:value-of select="@onselect"/>
			</h3>
			<xsl:if test="adl:permission">
				<ul xmlns="http://www.w3.org/1999/xhtml">
					<xsl:apply-templates select="adl:permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table xmlns="http://www.w3.org/1999/xhtml">
						<tr>
							<th>&#160;</th>
							<th>Property</th>
							<th>Prompt</th>
							<th>Documentation</th>
						</tr>
						<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
					</table>
				</xsl:when>
				<xsl:otherwise>
					<p>Showing all properties</p>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>

	<xsl:template match="adl:field">
		<tr xmlns="http://www.w3.org/1999/xhtml">
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="parent::adl:fieldgroup">
						<xsl:choose>
							<xsl:when test="position() = last()">fieldgroup-end</xsl:when>
							<xsl:otherwise>fieldgroup</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="parent::adl:auxlist">
						<xsl:choose>
							<xsl:when test="position() = last()">auxlist-end</xsl:when>
							<xsl:otherwise>auxlist</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<td>Field</td>
			<td>
				<xsl:value-of select="@property"/>
			</td>
			<td>
				<xsl:apply-templates select="adl:prompt"/>
			</td>
			<td>
				<xsl:apply-templates select="adl:help"/>
			</td>
			<td>
				<xsl:apply-templates select="adl:documentation"/>
			</td>
		</tr>
		<xsl:if test="adl:permission">
			<tr xmlns="http://www.w3.org/1999/xhtml">
				<td></td>
				<td colspan="3">
					<xsl:apply-templates select="adl:permission"/>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>


	<xsl:template match="adl:verb">
		<tr xmlns="http://www.w3.org/1999/xhtml">
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="parent::adl:fieldgroup">
						<xsl:choose>
							<xsl:when test="position() = last()">fieldgroup-end</xsl:when>
							<xsl:otherwise>fieldgroup</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="parent::adl:auxlist">
						<xsl:choose>
							<xsl:when test="position() = last()">auxlist-end</xsl:when>
							<xsl:otherwise>auxlist</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<td>Verb</td>
			<td>
				<xsl:value-of select="@verb"/>
				<xsl:if test="@dangerous='true'">[dangerous]</xsl:if>
			</td>
			<td>
				<xsl:apply-templates select="adl:prompt"/>
			</td>
			<td>
				<xsl:apply-templates select="adl:help"/>
			</td>
			<td>
				<xsl:apply-templates select="adl:documentation"/>
			</td>
		</tr>
		<xsl:if test="adl:permission">
			<tr xmlns="http://www.w3.org/1999/xhtml">
				<td></td>
				<td colspan="3">
					<xsl:apply-templates select="adl:permission"/>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>



	<xsl:template match="adl:auxlist">
		<tr xmlns="http://www.w3.org/1999/xhtml" class="auxlist-start">
			<th>Auxlist</th>
			<th>
				<xsl:value-of select="@property"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:prompt"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:help"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:documentation"/>
			</th>
		</tr>
		<tr xmlns="http://www.w3.org/1999/xhtml" class="auxlist">
			<th>On select:</th>
			<td>
				<xsl:value-of select="@onselect"/>
			</td>
			<td colspan="2">
				<xsl:choose>
					<xsl:when test="@properties='listed'">
						Showing the following properties
					</xsl:when>
					<xsl:otherwise>
						Showing all properties
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
		<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
	</xsl:template>

	<xsl:template match="adl:fieldgroup">
		<tr xmlns="http://www.w3.org/1999/xhtml" class="fieldgroup-start">
			<th>Auxlist</th>
			<th>
				<xsl:value-of select="@name"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:prompt"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:help"/>
			</th>
			<th>
				<xsl:apply-templates select="adl:documentation"/>
			</th>
		</tr>
		<tr xmlns="http://www.w3.org/1999/xhtml" class="adl:auxlist">
			<th>On select:</th>
			<td>
				<xsl:value-of select="@onselect"/>
			</td>
			<td colspan="2">
				<xsl:choose>
					<xsl:when test="@properties='listed'">
						Showing the following properties
					</xsl:when>
					<xsl:otherwise>
						Showing all properties
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
		<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
	</xsl:template>

	<xsl:template match="adl:option">
		<xsl:value-of select="@value"/>
		<xsl:if test="adl:prompt">
			: <xsl:apply-templates select="adl:prompt"/>
		</xsl:if>
		<xsl:if test="adl:help">
			(<i xmlns="http://www.w3.org/1999/xhtml">
				<xsl:apply-templates select="adl:prompt"/>
			</i>)
		</xsl:if>
	</xsl:template>


</xsl:stylesheet>
