<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
  xmlns="http://libs.cygnets.co.uk/adl/1.4/"
  xmlns:adl="http://libs.cygnets.co.uk/adl/1.4/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output encoding="UTF-8" method="xml" indent="yes" />

	<xsl:param name="locale" select="en-GB"/>

	<xsl:param name="css-stylesheet" 
			   select="'http://libs.cygnets.co.uk/adl/unstable/ADL/documentation.css'"/>

	<xsl:param name="detail" select="full"/>

	<xsl:template match="adl:application">
		<html>
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
          <dt>Entities</dt>
          <dd>
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
                  <xsl:value-of select="adl:documentation"/>
                </dd>
              </xsl:for-each>
            </dl>
          </dd>
          <dt>Defined types</dt>
          <dd>
            <dl>
              <xsl:for-each select="adl:typedef">
                <dt>
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="concat( '#typedef-', @name)"/>
                    </xsl:attribute>
                    <xsl:value-of select="@name"/>
                  </a>
                </dt>
              </xsl:for-each>
            </dl>
          </dd>
          <dt>Security groups</dt>
          <dd>
            <dl>
              <xsl:for-each select="adl:group">
                <dt>
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="concat( '#group-', @name)"/>
                    </xsl:attribute>
                    <xsl:value-of select="@name"/>
                  </a>
                </dt>
              </xsl:for-each>
            </dl>
          </dd>
        </dl>
        <hr/>
        <h2>Entities</h2>
        <xsl:apply-templates select="adl:entity"/>
        <hr/>
        <h2>
          Type Definitions
        </h2>
        <xsl:apply-templates select="adl:typedef"/>
        <hr/>
        <h2>Security groups</h2>
        <xsl:apply-templates select="adl:group"/>
			</body>
		</html>
	</xsl:template>

  <xsl:template match="adl:entity">
    <hr/>
    <a>
      <xsl:attribute name="name">
        <xsl:value-of select="concat( 'entity-', @name)"/>
      </xsl:attribute>
    </a>
    <h3>
      <xsl:value-of select="@name" />
    </h3>
    <xsl:apply-templates select="adl:documentation"/>
    <h4>Access control</h4>
    <table>
      <tr>
        <th>Group</th>
        <th>Permission</th>
      </tr>
      <xsl:for-each select="adl:permission">
        <tr>
          <td>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( '#group-', @group)"/>
              </xsl:attribute>
              <xsl:value-of select="@group"/>
            </a>
          </td>
          <td>
            <xsl:value-of select="@permission"/>
          </td>
        </tr>
      </xsl:for-each>
    </table>
    <h4>User interface</h4>
    <ul>
      <xsl:for-each select="adl:page|adl:list|adl:form">
        <li>
          <a>
            <xsl:attribute name="href">
              <xsl:value-of select="concat( '#page-', ancestor::adl:entity/@name, '-', @name)"/>
            </xsl:attribute>
            <xsl:value-of select="@name"/>
          </a>
        </li>
      </xsl:for-each>
    </ul>
    <h4>Properties</h4>
    <table>
      <tr class="header">
        <th>Property</th>
        <th>Type</th>
        <xsl:if test="not( $detail) or $detail = 'full'">
          <th>Req'd</th>
          <th>Def'lt</th>
          <th>Size</th>
          <th>Distinct</th>
          <th>Prompt</th>
          <th>Security overrides</th>
        </xsl:if>
      </tr>
      <xsl:apply-templates select=".//adl:property" />
    </table>
    <xsl:apply-templates select="adl:form"/>
    <xsl:apply-templates select="adl:list"/>
    <xsl:apply-templates select="adl:page"/>
    <a href="#top">[back to top]</a>
  </xsl:template>

  <xsl:template match="adl:property">
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
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="concat( 'property-', ancestor::adl:entity/@name, '-', @name)"/>
        </xsl:attribute>
      </a>
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
            <xsl:choose>
              <xsl:when test="@required='true'">
                (one to one-or-many)
              </xsl:when>
              <xsl:otherwise>
                (one to zero-or-many)
              </xsl:otherwise>
            </xsl:choose>
            of entities of type <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( '#entity-', @entity)"/>
              </xsl:attribute>
              <xsl:value-of select="@entity"/>
            </a>
          </xsl:when>
          <xsl:when test="@type='defined'">
            as <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( '#typedef-', @typedef)"/>
              </xsl:attribute>
              <xsl:value-of select="@typedef"/>
            </a>
          </xsl:when>
        </xsl:choose>
      </td>
      <xsl:if test="not( $detail) or $detail = 'full'">
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
          <xsl:apply-templates select="adl:prompt"/>&#160;
        </td>
        <td>
          <dl>
            <xsl:for-each select="adl:permission">
              <dt>
                <a>
                  <xsl:attribute name="href">
                    <xsl:value-of select="concat( '#group-', @group)"/>
                  </xsl:attribute>
                  <xsl:value-of select="@group"/>
                </a>
              </dt>
              <dd>
                <xsl:value-of select="@permission"/>
              </dd>
            </xsl:for-each>
          </dl>
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
        <td colspan="7">
          <xsl:apply-templates select="adl:option[ position()=1]"/>
        </td>
        <xsl:for-each select="adl:option[position() &gt; 1]">
          <tr>
            <xsl:attribute name="class">
              <xsl:value-of select="$rowclass"/>
            </xsl:attribute>
            <td colspan="7">
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
  </xsl:template>
  
  <xsl:template match="adl:typedef">
    <hr/>
    <a>
      <xsl:attribute name="name">
        <xsl:value-of select="concat( 'typedef-', @name)"/>
      </xsl:attribute>
    </a>
    <h3>
      <xsl:value-of select="@name" />
    </h3>
    <p>
      <xsl:choose>
        <xsl:when test="@type = 'string'">
          String matching
          "<xsl:value-of select="@pattern"/>"
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@minimum"/> &lt;
          <xsl:value-of select="@typedef"/> &lt;
          <xsl:value-of select="@maximum"/>
        </xsl:otherwise>
      </xsl:choose>
    </p>
    <xsl:apply-templates select="adl:documentation"/>
    <a href="#top">[back to top]</a>
  </xsl:template>

  <xsl:template match="adl:group">
    <hr/>
    <a>
      <xsl:attribute name="name">
        <xsl:value-of select="concat( 'group-', @name)"/>
      </xsl:attribute>
    </a>
    <h3>
      <xsl:value-of select="@name" />
    </h3>
    <xsl:apply-templates select="adl:documentation"/>
    <a href="#top">[back to top]</a>
  </xsl:template>
  
	<xsl:template match="adl:prompt">
		<!-- If I'm the prompt for the current locale, show me; 
    if I'm the default prompt, show me only if there isn't 
    one for the default locale -->
		<xsl:choose>
      <xsl:when test="not($locale) and @locale='en-GB'">
        <!-- something's not right with the locale parameter? -->
        <xsl:apply-templates/>
      </xsl:when>
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
    <xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="adl:help">
		<!-- If I'm the helptext for the current locale, show me; 
    if I'm the default helptext, show me only if there isn't 
    one for the default locale -->
		<xsl:choose>
      <xsl:when test="not($locale) and @locale='en-GB'">
        <!-- something's not right with the locale parameter? -->
        <xsl:apply-templates/>
      </xsl:when>
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
		<div class="documentation">
			<xsl:value-of select="."/>
			<xsl:if test="adl:reference">
				<h5>See also</h5>
				<ul>
					<xsl:apply-templates select="adl:reference"/>
				</ul>
			</xsl:if>
		</div>
	</xsl:template>

	<xsl:template match="adl:reference">
		<xsl:variable name="abbr" select="@abbr"/>
		<xsl:variable name="specification" select="/adl:application/adl:specification[@abbr=$abbr]"/>
		<li>
			<xsl:choose>
				<xsl:when test="@entity">
					<a>
						<xsl:attribute name="href">
							<xsl:value-of select="concat('#',@entity)"/>
						</xsl:attribute>
						<xsl:value-of select="@entity"/>
						<xsl:if test="@property">
							: <xsl:value-of select="@property"/>
						</xsl:if>
					</a>
				</xsl:when>
				<xsl:when test="$specification/@url">
					<a>
						<xsl:attribute name="href">
							<xsl:choose>
								<xsl:when test="@section">
									<xsl:value-of select="concat( $specification/@url, @section)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$specification/@url"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<xsl:value-of select="$specification/@name"/>:
						<xsl:if test="@section">
							<xsl:value-of select="@section"/>:
						</xsl:if>
					</a>
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$specification/@name"/>:
					<xsl:if test="@section">
						<xsl:value-of select="@section"/>:
					</xsl:if>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</li>
	</xsl:template>

	<xsl:template match="adl:form">
		<div class="form">
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="concat('page-', ancestor::adl:entity/@name, '-', @name)"/>
        </xsl:attribute>
      </a>
      <h4>
				Form '<xsl:value-of select="@name"/>' of entity 
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat('#entity-', ancestor::adl:entity/@name)"/>
          </xsl:attribute>
          <xsl:value-of select="ancestor::adl:entity/@name"/>
        </a>
			</h4>
			<xsl:if test="adl:permission">
				<h5>Permissions</h5>
				<ul>
					<xsl:apply-templates select="permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table>
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
		<div class="page">
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="concat('page-', ancestor::adl:entity/@name, '-', @name)"/>
        </xsl:attribute>
      </a>
      <h4>
        Page '<xsl:value-of select="@name"/>' of entity
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat('#entity-', ancestor::adl:entity/@name)"/>
          </xsl:attribute>
          <xsl:value-of select="ancestor::adl:entity/@name"/>
        </a>
			</h4>
			<xsl:if test="adl:permission">
				<ul>
					<xsl:apply-templates select="permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table>
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
		<div class="list">
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="concat('page-', ancestor::adl:entity/@name, '-', @name)"/>
        </xsl:attribute>
      </a>
			<h4>
        List '<xsl:value-of select="@name"/>' of entity
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat('#entity-', ancestor::adl:entity/@name)"/>
          </xsl:attribute>
          <xsl:value-of select="ancestor::adl:entity/@name"/>
        </a>, on select 
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat( '#page-', ancestor::adl:entity/@name, '-', @onselect)"/>
          </xsl:attribute>
          <xsl:value-of select="@onselect"/>
        </a>
			</h4>
			<xsl:if test="adl:permission">
				<ul>
					<xsl:apply-templates select="adl:permission"/>
				</ul>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@properties='listed'">
					<p>Showing the following properties</p>
					<table>
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
		<tr>
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
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="concat( '#property-', ancestor::adl:entity/@name, '-', @property)"/>
          </xsl:attribute>
          <xsl:value-of select="@property"/>
        </a>
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
			<tr>
				<td></td>
				<td colspan="3">
					<xsl:apply-templates select="adl:permission"/>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>


	<xsl:template match="adl:verb">
		<tr>
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
			<tr>
				<td></td>
				<td colspan="3">
					<xsl:apply-templates select="adl:permission"/>
				</td>
			</tr>
		</xsl:if>
	</xsl:template>



	<xsl:template match="adl:auxlist">
		<tr class="auxlist-start">
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
		<tr class="auxlist">
			<th>
        <xsl:if test="@onselect">On  select:</xsl:if></th>
			<td>
        <a>
          <xsl:attribute name="href">
            <xsl:variable name="propname" select="@property"/> 
            <xsl:variable name="targetent">
              <xsl:choose>
                <xsl:when test="ancestor::adl:entity//adl:property[@name=$propname]/@entity">
                  <xsl:value-of select="ancestor::adl:entity//adl:property[@name=$propname]/@entity"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="ancestor::adl:entity/@name"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat( '#page-', $targetent, '-', @onselect)"/>
          </xsl:attribute>
          <xsl:value-of select="@onselect"/>
        </a>
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
		<tr class="fieldgroup-start">
			<th>Field group</th>
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
		<xsl:apply-templates select="adl:field|adl:fieldgroup|adl:auxlist|adl:verb"/>
	</xsl:template>

	<xsl:template match="adl:option">
		<xsl:value-of select="@value"/>
		<xsl:if test="adl:prompt">
			: <xsl:apply-templates select="adl:prompt"/>
		</xsl:if>
		<xsl:if test="adl:help">
			(<i>
				<xsl:apply-templates select="adl:prompt"/>
			</i>)
		</xsl:if>
	</xsl:template>


</xsl:stylesheet>
