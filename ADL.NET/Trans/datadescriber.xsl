<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output encoding="utf-8" method="html" indent="yes" />

  <xsl:param name="locale" select="en-UK"/>

  <xsl:template match="application">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>
          Data definition for the <xsl:value-of select="@name"/> application
          version <xsl:value-of select="@version"/>
        </title>
        <link href="styles/default.css" rel="stylesheet" type="text/css" />
      </head>
      <body>
        <h1>
          Data definition for the <xsl:value-of select="@name"/> application version <xsl:value-of select="@version"/>
        </h1>
        <xsl:apply-templates select="documentation"/>

        <xsl:for-each select="entity">
          <h2>
            <xsl:value-of select="@name" />
          </h2>
          <xsl:apply-templates select="documentation"/>
          <dl>
            <xsl:for-each select="permission">
              <dt>
                Group:
                <xsl:value-of select="@group"/>
              </dt>
              <dd>
                Permissions:
                <xsl:value-of select="@permission"/>
              </dd>
            </xsl:for-each>
          </dl>
          <table>
            <tr class="header">
              <th class="white">Property</th>
              <th class="white">Type</th>
              <th class="white">Req'd</th>
              <th class="white">Def'lt</th>
              <th class="white">Size</th>
              <th class="white">Distinct</th>
              <th class="white">Prompt</th>
            </tr>
            <xsl:for-each select="property" >
              <tr>
                <xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="position() mod 2 = 0">even</xsl:when>
                    <xsl:otherwise>odd</xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <td>
                  <xsl:value-of select="@name"/>&#160;
                </td>
                <td>
                  <xsl:value-of select="@type"/>
                  <xsl:if test="@type='entity'">
                    of type <xsl:value-of select="@entity"/>
                  </xsl:if>
                  <xsl:if test="@definition">
                    :
                    <xsl:variable name="definition">
                      <xsl:value-of select="@definition"/>
                    </xsl:variable>
                    <xsl:variable name="defined-type">
                      <xsl:value-of select="/application/definition[@name=$definition]/@type"/>
                    </xsl:variable>
                    <xsl:choose>
                      <xsl:when  test="$defined-type = 'string'">
                        String matching
                        "<xsl:value-of select="/application/definition[@name=$definition]/@pattern"/>"
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/application/definition[@name=$definition]/@minimum"/> &lt;
                        <xsl:value-of select="@definition"/> &lt;
                        <xsl:value-of select="/application/definition[@name=$definition]/@maximum"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:if>
                  &#160;
                </td>
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
                  <xsl:for-each select="prompt">
                    <xsl:apply-templates select="@prompt"/>&#160;
                  </xsl:for-each>
                </td>
              </tr>
              <xsl:if test="help">
                <tr>
                  <td>
                      <xsl:apply-templates select="help"/>&#160;
                  </td>
                </tr>
              </xsl:if>
              <xsl:if test="documentation">
                <tr>
                  <td>
                    <xsl:apply-templates select="help"/>&#160;
                  </td>
                </tr>
              </xsl:if>
            </xsl:for-each>
          </table>
        </xsl:for-each>
        <xsl:apply-templates select="form"/>
        <xsl:apply-templates select="list"/>
        <xsl:apply-templates select="page"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="prompt">
    <!-- If I'm the prompt for the current locale, show me; 
    if I'm the default prompt, show me only if there isn't 
    one for the default locale -->
    <xsl:choose>
      <xsl:when test="@locale=$locale">
        <xsl:value-of select="@prompt"/>
      </xsl:when>
      <xsl:when test="@locale='default'">
        <xsl:choose>
          <xsl:when test="../prompt[@locale=$locale]"/>
          <xsl:otherwise>
            <xsl:value-of select="@prompt"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="help">
    <!-- If I'm the helptext for the current locale, show me; 
    if I'm the default helptext, show me only if there isn't 
    one for the default locale -->
    <xsl:choose>
      <xsl:when test="@locale=$locale">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@locale='default'">
        <xsl:choose>
          <xsl:when test="../help[@locale=$locale]"/>
          <xsl:otherwise>
            <xsl:apply-templates/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="documentation">
    <div xmlns="http://www.w3.org/1999/xhtml" class="documentation">
      <xsl:apply-templates />
    </div> 
  </xsl:template>

  <xsl:template match="form">
    <div xmlns="http://www.w3.org/1999/xhtml">
    <h3 xmlns="http://www.w3.org/1999/xhtml">
      Form <xsl:value-of select="@name"/>
    </h3>
    <xsl:if test="permission">
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
            <xsl:apply-templates select="field|fieldgroup|auxlist|verb"/>
          </table>
        </xsl:when>
        <xsl:otherwise>
          <p>Showing all properties</p>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template match="page">
    <div xmlns="http://www.w3.org/1999/xhtml">
      <h3 xmlns="http://www.w3.org/1999/xhtml">
        Page <xsl:value-of select="@name"/>
      </h3>
      <xsl:if test="permission">
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
            <xsl:apply-templates select="field|fieldgroup|auxlist|verb"/>
          </table>
        </xsl:when>
        <xsl:otherwise>
          <p>Showing all properties</p>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template match="list">
    <div xmlns="http://www.w3.org/1999/xhtml">
      <h3 xmlns="http://www.w3.org/1999/xhtml">
        List <xsl:value-of select="@name"/>, on select <xsl:value-of select="onselect"/>
      </h3>
      <xsl:if test="permission">
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
            <xsl:apply-templates select="field|fieldgroup|auxlist|verb"/>
          </table>
        </xsl:when>
        <xsl:otherwise>
          <p>Showing all properties</p>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template match="field">
    <tr xmlns="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="parent::fieldgroup">
            <xsl:choose>
              <xsl:when test="position() = last()">fieldgroup-end</xsl:when>
              <xsl:otherwise>fieldgroup</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="parent::auxlist">
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
        <xsl:apply-templates select="prompt"/>
      </td>
      <td>
        <xsl:apply-templates select="help"/>
      </td>
      <td>
        <xsl:apply-templates select="documentation"/>
      </td>
    </tr>
    <xsl:if test="permission">
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td></td>
        <td colspan="3">
          <xsl:apply-templates select="permission"/>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>


  <xsl:template match="verb">
    <tr xmlns="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="parent::fieldgroup">
            <xsl:choose>
              <xsl:when test="position() = last()">fieldgroup-end</xsl:when>
              <xsl:otherwise>fieldgroup</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="parent::auxlist">
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
        <xsl:apply-templates select="prompt"/>
      </td>
      <td>
        <xsl:apply-templates select="help"/>
      </td>
      <td>
        <xsl:apply-templates select="documentation"/>
      </td>
    </tr>
    <xsl:if test="permission">
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td></td>
        <td colspan="3">
          <xsl:apply-templates select="permission"/>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>



  <xsl:template match="auxlist">
    <tr xmlns="http://www.w3.org/1999/xhtml" class="auxlist-start">
      <th>Auxlist</th>
      <th>
        <xsl:value-of select="@property"/>
      </th>
      <th>
        <xsl:apply-templates select="prompt"/>
      </th>
      <th>
        <xsl:apply-templates select="help"/>
      </th>
      <th>
        <xsl:apply-templates select="documentation"/>
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
    <xsl:apply-templates select="field|fieldgroup|auxlist|verb"/>
  </xsl:template>

  <xsl:template match="fieldgroup">
    <tr xmlns="http://www.w3.org/1999/xhtml" class="fieldgroup-start">
      <th>Auxlist</th>
      <th>
        <xsl:value-of select="@name"/>
      </th>
      <th>
        <xsl:apply-templates select="prompt"/>
      </th>
      <th>
        <xsl:apply-templates select="help"/>
      </th>
      <th>
        <xsl:apply-templates select="documentation"/>
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
    <xsl:apply-templates select="field|fieldgroup|auxlist|verb"/>
  </xsl:template>




</xsl:stylesheet>
