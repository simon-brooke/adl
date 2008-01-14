<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
    C1873 SRU Hospitality
    adl2views.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into velocity view templates
    
    $Author: af $
    $Revision: 1.2 $
    $Date: 2008-01-14 16:53:31 $
  -->
  <!-- WARNING WARNING WARNING: Do NOT reformat this file! 
     Whitespace (or lack of it) is significant! -->

  <!--
    TODO: this transform BADLY needs to be refactored! It is /crap/!
  -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

  <!-- The locale for which these views are generated 
      TODO: we need to generate views for each available locale, but this is not
      yet implemented. When it is we will almost certainly still need a 'default locale' -->
  <xsl:param name="locale" select="en-UK"/>

  <!-- what's all this about? the objective is to get the revision number of the 
    transform into the output, /without/ getting that revision number overwritten 
    with the revision number of the generated file when the generated file is 
    stored to CVS -->

  <xsl:variable name="transform-rev1"
                select="substring( '$Revision: 1.2 $', 11)"/>
  <xsl:variable name="transform-revision"
                select="substring( $transform-rev1, 0, string-length( $transform-rev1) - 1)"/>


  <xsl:template match="application">
    <output>
      <xsl:apply-templates select="entity"/>
      <!-- make sure extraneous junk doesn't get into the last file generated,
      by putting it into a separate file -->
      <xsl:comment> [ cut here: next file 'tail.txt' ] </xsl:comment>
    </output>
  </xsl:template>

  <xsl:template match="entity">
    <xsl:apply-templates select="form"/>
    <xsl:apply-templates select="list"/>
    <xsl:text>
    </xsl:text>
    <xsl:comment> [ cut here: next file '<xsl:value-of select="concat( @name, '/maybedelete.auto.vm')"/>' ] </xsl:comment>
    <xsl:text>
    </xsl:text>
    <html>
      <xsl:comment>
        #set( $title = "<xsl:value-of select="concat( 'Really delete ', @name)"/> $instance.UserIdentifier")
      </xsl:comment>
      <head>
        <xsl:call-template name="head"/>
        <xsl:comment>
          Auto generated Velocity maybe-delete form for <xsl:value-of select="@name"/>,
          generated from ADL.

          Generated using adl2views.xsl <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
        ${Ajax.InstallScripts()}
        ${FormHelper.InstallScripts()}
        ${Validation.InstallScripts()}
        ${Scriptaculous.InstallScripts()}
      </head>
      <body>
        <xsl:call-template name="top"/>
        <form action="delete.rails">
          <xsl:choose>
            <xsl:when test="@natural-key">
              <!-- create a hidden widget for the natural primary key -->
              ${FormHelper.HiddenField( "instance.<xsl:value-of select="@natural-key"/>")}
            </xsl:when>
            <xsl:otherwise>
              <!-- there isn't a natural primary key; create a hidden widget 
                  for the abstract primary key -->
              ${FormHelper.HiddenField( "instance.Id")}
            </xsl:otherwise>
          </xsl:choose>
          <table>
            <tr align="left" valign="top" class="actionDangerous">
              <td class="actionDangerous">
                Really delete?
              </td>
              <td class="widget">
                <select name="reallydelete">
                  <option value="false">No, don't delete it</option>
                  <option value="true">Yes, do delete it</option>
                </select>
              </td>
              <td class="actionDangerous" style="text-align:right">
                <input type="submit" name="command" value="Go!" />
              </td>
            </tr>
          </table>
        </form>
        <xsl:call-template name="foot"/>
      </body>
    </html>
  </xsl:template>

  <!-- layout of forms -->

  <xsl:template match="form">
    <xsl:variable name="formname" select="@name"/>
    <xsl:variable name="aoran">
      <xsl:variable name="initial" select="substring( ancestor::entity/@name, 1, 1)"/>
      <xsl:choose>
        <xsl:when test="$initial = 'A'">an</xsl:when>
        <xsl:when test="$initial = 'E'">an</xsl:when>
        <xsl:when test="$initial = 'I'">an</xsl:when>
        <xsl:when test="$initial = 'O'">an</xsl:when>
        <xsl:when test="$initial = 'U'">an</xsl:when>
        <xsl:otherwise>a</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>
    </xsl:text>
    <xsl:comment> [ cut here: next file '<xsl:value-of select="concat( ancestor::entity/@name, '/', @name)"/>.auto.vm' ] </xsl:comment>
    <xsl:text>
    </xsl:text>
    <html>
      <xsl:comment>
        #if ( $instance)
        #set( $title = "<xsl:value-of select="concat( 'Edit ', ' ', ancestor::entity/@name)"/> $instance.UserIdentifier")
        #else
        #set( $title = "Add a new <xsl:value-of select="ancestor::entity/@name"/>")
        #end
      </xsl:comment>
      <head>
        <xsl:call-template name="head"/>
        <xsl:comment>
          Auto generated Velocity form for <xsl:value-of select="@name"/>,
          generated from ADL.

          Generated using adl2views.xsl <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
        ${Ajax.InstallScripts()}
        ${FormHelper.InstallScripts()}
        ${Validation.InstallScripts()}
        ${Scriptaculous.InstallScripts()}
        ${ShuffleWidgetHelper.InstallScripts()}
        <script type="text/javascript" language='JavaScript1.2' src="../script/panes.js"></script>

        <script type='text/javascript' language='JavaScript1.2'>
          var panes = new Array( <xsl:for-each select='fieldgroup'>
            "<xsl:value-of select='@name'/>"<xsl:choose>
              <xsl:when test="position() = last()"/>
              <xsl:otherwise>,</xsl:otherwise>
            </xsl:choose></xsl:for-each> );

          function performInitialisation()
          {
          <xsl:for-each select="../property[@type='link']">
            document.<xsl:value-of select="$formname"/>.<xsl:value-of select="@name"/>.submitHandler = shuffleSubmitHandler;
          </xsl:for-each>
            var validator = new Validation('<xsl:value-of select="$formname"/>', {immediate : true, useTitles : true});
          <xsl:if test="fieldgroup">
            switchtab( '<xsl:value-of select="fieldgroup[1]/@name"/>');
          </xsl:if>
          }

        </script>
        <style type="text/css">
          <xsl:for-each select="../property[@required='true']">
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
        <div class="content">
          #if ( $Flash.errors)
          <div class="warning">
          <h2>Errors were encountered</h2>
          
          <ul>
            #foreach ($error in $Flash.errors)
            <li>
              $error
            </li>
            #end
          </ul>
          </div>
          #end
          #if ( $messages.Count == 0)
          <!-- if I try to test for $messages.Count &gt; 0,  I get the &gt; copied straight through to 
          the output instead of the entity value being substituted(?) -->
          #else
          <div class="information">
            #foreach ( $message in $messages)
            <p>
              $message
            </p>
            #end
          </div>
          #end
          <form method="post" onsubmit="invokeSubmitHandlers( this)">
            <xsl:attribute name="action">
              <xsl:value-of select="concat( $formname, 'SubmitHandler.rails')"/>
            </xsl:attribute>
            <xsl:attribute name="name">
              <xsl:value-of select="$formname"/>
            </xsl:attribute>
            <xsl:attribute name="id">
              <xsl:value-of select="$formname"/>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="ancestor::entity/@natural-key">
                <xsl:variable name="keyfield" select="ancestor::entity/@natural-key"/>
                <xsl:choose>
                  <xsl:when test="@properties='all'">
                    <!-- no need to emit a hidden widget for the natural key, as there will be a 
                      non-hidden one anyway -->
                  </xsl:when>
                  <xsl:when test="field[@name=$keyfield]">
                    <!-- no need to emit a hidden widget for the natural key, as there will be a 
                      non-hidden one anyway -->
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- create a hidden widget for the natural primary key -->
                    ${FormHelper.HiddenField( "instance.<xsl:value-of select="$keyfield"/>")}
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <!-- there isn't a natural primary key; create a hidden widget 
                  for the abstract primary key -->
                ${FormHelper.HiddenField( "instance.Id")}
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="fieldgroup">
              <div id="tabbar">
                <xsl:for-each select="fieldgroup">
                  <span class="tab">
                    <xsl:attribute name="id">
                      <xsl:value-of select="concat( @name, 'tab')"/>
                    </xsl:attribute>
                    <a>
                      <xsl:attribute name="href">
                        <xsl:value-of select="concat( '#', @name, 'anchor')"/>
                      </xsl:attribute>
                      <xsl:attribute name="onclick">switchtab( '<xsl:value-of select="@name"/>'); return false;</xsl:attribute>
                      <xsl:call-template name="showprompt">
                        <xsl:with-param name="fallback" select="@name"/>
                      </xsl:call-template>
                    </a>
                  </span>
                </xsl:for-each>
              </div>
            </xsl:if>
            <xsl:apply-templates select="fieldgroup"/>
            <div class="pane">
              <table>
                <xsl:choose>
                  <xsl:when test="@properties='listed'">
                    <xsl:apply-templates select="field|auxlist|verb"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="ancestor::entity/property"/>
                  </xsl:otherwise>
                </xsl:choose>
                <tr class="actionSafe">
                  <td class="actionSafe" colspan="2">
                    To save this record
                  </td>
                  <td class="actionSafe" style="text-align:right">
                    <button type="submit" name="command" value="store">Save this!</button>
                  </td>
                </tr>
                <tr align="left" valign="top" class="actionDangerous">

                  <td class="actionDangerous" colspan="2">
                    To delete this record
                  </td>
                  <td class="actionDangerous" style="text-align:right">
                    <button type="submit" name="command" value="delete">Delete this!</button>
                  </td>
                </tr>
              </table>
            </div>
          </form>
        </div>
        <xsl:call-template name="foot"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="fieldgroup">
    <div class="pane">
      <xsl:attribute name="id">
        <xsl:value-of select="concat( @name, 'pane')"/>
      </xsl:attribute>
      <xsl:attribute name="style">
        <xsl:choose>
          <xsl:when test="position() = 1"/>
          <xsl:otherwise>display: none</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <a>
        <xsl:attribute name="name">
          <xsl:value-of select="concat( @name, 'anchor')"/>
        </xsl:attribute>
        <h3>
          <xsl:call-template name="showprompt">
            <xsl:with-param name="fallback" select="@name"/>
          </xsl:call-template>
        </h3>
      </a>
      <table>
        <xsl:apply-templates select="field|verb|auxlist"/>
      </table>
    </div>
  </xsl:template>

  <xsl:template match="auxlist">
    <xsl:variable name="listprop" select="@property"/>
    <xsl:variable name="farent" select="ancestor::entity/property[@name=$listprop]/@entity"/>
    <xsl:variable name="nearent" select="ancestor::entity/@name"/>
    <xsl:variable name="farid">
      <xsl:choose>
        <xsl:when test="//entity[@name=$farent]/@natural-key">
          <xsl:value-of select="//entity[@name=$farent]/@natural-key"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat( '', 'Id')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="farkey">
      <xsl:value-of select="//entity[@name=$farent]/property[@entity=$nearent]/@name"/>
    </xsl:variable>
    <xsl:variable name="nearkey">
      <xsl:choose>
        <xsl:when test="ancestor::entity[@natural-key]">
          <xsl:value-of select="ancestor::entity[@natural-key]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat( '', 'Id')"/>
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
              <xsl:value-of select="concat( $action, '.rails?', $farkey, '=$instance.', $nearkey)"/>
            </xsl:attribute>
            Add a new <xsl:value-of select="$farent"/>
          </a>
        </td>
      </tr>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="@properties='listed'">
        <tr>
          <xsl:for-each select="field">
            <xsl:variable name="fieldprop" select="@property"/>
            <th>
              <!-- Getting the prompt for the field from a property of another entity is a bit 
                complex... -->
              <xsl:call-template name="showprompt">
                <xsl:with-param name="node" select="//entity[@name=$farent]/property[@name=$fieldprop]"/>
                <xsl:with-param name="fallback" select="@property"/>
              </xsl:call-template>
            </th>
          </xsl:for-each>
          <th>
            -
          </th>
        </tr>
        #foreach( $item in $instance.<xsl:value-of select="@property"/>)
        #if ( $velocityCount % 2 == 0)
        #set( $oddity = "even")
        #else
        #set( $oddity = "odd")
        #end
        <tr class="$oddity">
          <xsl:for-each select="field">
            <xsl:variable name="fieldprop" select="@property"/>
            <td>
              <xsl:choose>
                <xsl:when test="//entity[@name=$farent]/property[@name=$fieldprop]/@type='entity'">
                  #if ( $item.<xsl:value-of select="@property"/>)
                  $item.<xsl:value-of select="@property"/>.UserIdentifier
                  #end
                </xsl:when>
                <xsl:when test="//entity[@name=$farent]/property[@name=$fieldprop]/option">
                  <!-- if we can get a prompt value for the option, it would be better to 
                  show it than the raw value-->
                  <xsl:for-each select="//entity[@name=$farent]/property[@name=$fieldprop]/option">
                    #if ( $item.<xsl:value-of select="$fieldprop"/> == '<xsl:value-of select="@value"/>')
                    <xsl:call-template name="showprompt">
                      <xsl:with-param name="fallback" select="@value"/>
                    </xsl:call-template>
                    #end
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  $!item.<xsl:value-of select="@property"/>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          </xsl:for-each>
          <td>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( $action, '.rails?', $farid, '=$item.', $farid)"/>
              </xsl:attribute>
              Edit!
            </a>
          </td>
        </tr>
        #end
      </xsl:when>
      <xsl:otherwise>
        <!-- properties not listed, so therefore presumably all. TODO: This won't work, rewrite. Need to
        find the entity of the property this auxlist depends on, and then interrogate that -->
        <tr>
          <xsl:for-each select="ancestor::entity/property[@distinct='user']">
            <th>
              <xsl:choose>
                <xsl:when test="prompt[@locale=$locale]">
                  <xsl:value-of select="prompt[@locale=$locale]/@prompt"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@name"/>
                </xsl:otherwise>
              </xsl:choose>
            </th>
          </xsl:for-each>
          <th>-</th>
        </tr>
        #foreach( $instance in $instances)
        #if ( $velocityCount % 2 == 0)
        #set( $oddity = "even")
        #else
        #set( $oddity = "odd")
        #end
        <tr class="$oddity">
          <xsl:for-each select="ancestor::entity/property[@distinct='user']">
            <td>
              $!instance.<xsl:value-of select="@name"/>
            </td>
          </xsl:for-each>
          <td>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( $action, '.rails?', ../@name, 'Id=$instance.Id')"/>
              </xsl:attribute>
              Edit!
            </a>
          </td>
        </tr>
        #end
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="verb">
    <xsl:variable name="class">
      <xsl:choose>
        <xsl:when test="@dangerous='true'">actionDangerous</xsl:when>
        <xsl:otherwise>actionSafe</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <tr>
      <xsl:attribute name="class"><xsl:value-of select="$class"/></xsl:attribute>
      <td colspan="2">
        <xsl:attribute name="class">
          <xsl:value-of select="$class"/>
        </xsl:attribute>
        <xsl:apply-templates select="help[@locale = $locale]"/>
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
            <xsl:with-param name="fallback" select="@verb"/>
          </xsl:call-template>
        </button>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="field">
    <xsl:variable name="propname">
      <xsl:value-of select="@property"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="ancestor::entity/property[@name=$propname]">
        <!-- there is a real property -->
        <xsl:apply-templates select="ancestor::entity/property[@name=$propname]">
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
        Computed field '<xsl:value-of select="$propname"/>'? TODO: Not yet implememented
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="property[@type='link']">
    <!-- note! this template is only intended to match properties in the context of a form:
      it may be we need to add a mode to indicate this! -->
    <!-- for links we implement a shuffle widget, which extends over both columns -->
    <!-- TODO: Permissions! -->
    <xsl:param name="oddness" select="odd"/>
    <tr>
      <xsl:attribute name="class">
        <xsl:value-of select="$oddness"/>
      </xsl:attribute>
      <td class="label" rowspan="2">
        ${FormHelper.LabelFor( "instance.<xsl:value-of select="@name"/>", "<xsl:call-template name="showprompt">
          <xsl:with-param name="fallback" select="@name"/>
        </xsl:call-template>")}
      </td>
      <td class="widget" colspan="2">
        <table>
          <tr>
            <td class="widget" rowspan="2">
              ${ShuffleWidgetHelper.UnselectedOptions( "<xsl:value-of select="concat( @name, '_unselected')"/>", <xsl:value-of select="concat( '$all_', @name)"/>, $instance.<xsl:value-of select="@name"/>)}
            </td>            
            <td class="widget">
              <input type="button" value="include &gt;&gt;">
                <xsl:attribute name="onclick">
                  <xsl:value-of select="concat( 'shuffle(', @name, '_unselected, ', @name, ')')"/>
                </xsl:attribute>
              </input>
            </td>
            <td class="widget" rowspan="2">
              ${ShuffleWidgetHelper.SelectedOptions( "<xsl:value-of select="@name"/>", $instance.<xsl:value-of select="@name"/>)}
            </td>
          </tr>
          <tr>
            <td class="widget">
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
        <xsl:apply-templates select="help[@locale = $locale]"/>
      </td>
    </tr>
  </xsl:template>


  <xsl:template match="property[@type='text']">
    <!-- note! this template is only intended to match properties in the context of a form:
      it may be we need to add a mode to indicate this! -->
    <!-- text box widgets, like shuffle widgets, extend over both columns -->
    <!-- TODO: Permissions! -->
    <xsl:param name="oddness" select="odd"/>
    <xsl:variable name="if-missing">
      <xsl:choose>
        <xsl:when test="if-missing[@locale = $locale]">
          <xsl:value-of select="if-missing[@locale = $locale]"/>
        </xsl:when>
        <xsl:when test="required='true'">You must provide a value for <xsl:value-of select="@name"/></xsl:when>
        <xsl:otherwise>Enter a value for <xsl:value-of select="@name"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <tr>
      <xsl:attribute name="class">
        <xsl:value-of select="$oddness"/>
      </xsl:attribute>
      <td class="label" rowspan="2">
        ${FormHelper.LabelFor( "instance.<xsl:value-of select="@name"/>", "<xsl:choose>
          <xsl:when test="prompt[@locale = $locale]">
            <xsl:apply-templates select="prompt[@locale = $locale]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@name"/>
          </xsl:otherwise>
        </xsl:choose>")}
      </td>
      <td class="widget" colspan="2">
        ${FormHelper.TextArea( "instance.<xsl:value-of select="@name"/>", "%{rows='8' cols='60' title='<xsl:value-of select="$if-missing"/>'}")}
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
        <xsl:apply-templates select="help[@locale = $locale]"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="property">
    <xsl:param name="oddness" select="odd"/>
    <!-- note! this template is only intended to match properties in the context of a form:
      it may be we need to add a mode to indicate this! -->
    <!-- TODO: This really needs to be refactored -->
    <!-- TODO: we really need to be able to handle different permissions for different 
    groups. If the current user is not a member of a group which has read access to 
    this widget, the widget shouldn't even appear (unless they have write but not read?); 
    if they are not a member of a group which has write access, the widget should be 
    disabled. I don't have time to implement this now as it is not trivial, but it is 
    important! -->
    <xsl:variable name="if-missing">
      <xsl:choose>
        <xsl:when test="if-missing[@locale = $locale]">
          <xsl:value-of select="if-missing[@locale = $locale]"/>
        </xsl:when>
        <xsl:when test="@required='true'">
          You must provide a value for <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:when test="@type='defined'">
          The value for <xsl:value-of select="@name"/> must be <xsl:value-of select="@definition"/>
        </xsl:when>
        <xsl:when test="@type='entity'">
          The value for <xsl:value-of select="@name"/> must be an instance of <xsl:value-of select="@entity"/>
        </xsl:when>
        <xsl:otherwise>
          The value for <xsl:value-of select="@name"/> must be <xsl:value-of select="@type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- TODO: this is a one-database-role permission model, because that's all SRU needs. 
        Different permissions for different database groups is much more complex! Also, this 
        handles permissions on only properties and entities, not on forms. Perhaps we need a 
        Helper class? -->
    <xsl:variable name="permission">
      <xsl:choose>
        <xsl:when test="permission">
          <xsl:value-of select="permission[position()=1]/@permission"/>
        </xsl:when>
        <xsl:when test="../permission">
          <xsl:value-of select="../permission[position()=1]/@permission"/>
        </xsl:when>
        <xsl:otherwise>edit</xsl:otherwise>
      </xsl:choose>
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
          <xsl:when test="$permission='none'">
            [You are not authorised to see this data]
          </xsl:when>
          <xsl:when test="$permission='read'">
            <xsl:choose>
              <xsl:when test="@type='entity'">
                <xsl:value-of select="concat('$instance.', @name, '.UserIdentifier')"/>
              </xsl:when>
              <!-- TODO: if @type='list' or 'link', should generate Velocity to generate ul list
                of UserIdentifiers
              -->
              <xsl:otherwise>
                <xsl:value-of select="concat('$instance.', @name)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- TODO: if $permission='insert', then you should get an editable widget if there 
          is no current value, else a 'not authorised' message -->
          <!-- TODO: if $permission='noedit', then you should get an editable widget if there 
          is no current value, else just the value -->
          <xsl:when test="@type='entity'">
            <!-- a menu of the appropriate entity -->
            #if ( $instance)
              ${FormHelper.Select( "instance.<xsl:value-of select="@name"/>", $instance.<xsl:value-of select="@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{firstoption='[unset]' firstoptionvalue='-1' text='UserIdentifier' value='<xsl:value-of select="concat( '', 'Id')"/>' title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #else
              ${FormHelper.Select( "instance.<xsl:value-of select="@name"/>", $<xsl:value-of select="@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{firstoption='[unset]' firstoptionvalue='-1' text='UserIdentifier' value='<xsl:value-of select="concat( '', 'Id')"/>' title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #end
          </xsl:when>
          <xsl:when test="@type='list'">
            <!-- a multi-select menu of the appropriate entity -->
            ${FormHelper.Select( "instance.<xsl:value-of select="@name"/>", $instance.<xsl:value-of select="@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{multiple='multiple' size='8' text='UserIdentifier' value='<xsl:value-of select="concat( '', 'Id')"/>' title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
          </xsl:when>
          <xsl:when test="@type='defined'">
            <!-- likely to be hardest of all... -->
            <xsl:variable name="definition">
              <xsl:value-of select="@definition"/>
            </xsl:variable>
            <xsl:variable name="maximum">
              <xsl:value-of select="/application/definition[@name=$definition]/@maximum"/>
            </xsl:variable>
            <xsl:variable name="minimum">
              <xsl:value-of select="/application/definition[@name=$definition]/@minimum"/>
            </xsl:variable>
            <xsl:variable name="validationpattern">
              <xsl:value-of select="/application/definition[@name=$definition]/@pattern"/>
            </xsl:variable>
            <xsl:variable name="definedtype">
              <xsl:value-of select="/application/definition[@name=$definition]/@type"/>
            </xsl:variable>
            <xsl:variable name="definedsize">
              <xsl:value-of select="/application/definition[@name=$definition]/@size"/>
            </xsl:variable>
            <input type="text">
              <xsl:attribute name="class">
                <xsl:if test="@required='true'">required </xsl:if>
                <xsl:choose>
                  <xsl:when test="$definedtype='integer'">validate-digits</xsl:when>
                  <xsl:when test="$definedtype='real'">validate-number</xsl:when>
                  <xsl:when test="$definedtype='money'">validate-number</xsl:when>
                  <xsl:when test="$definedtype='date'">date-field validate-date</xsl:when>
                </xsl:choose>
              </xsl:attribute>
              <xsl:attribute name="id">
                <xsl:value-of select="concat( 'instance_', @name)"/>
              </xsl:attribute>
              <xsl:attribute name="name">
                <xsl:value-of select="concat( 'instance.', @name)"/>
              </xsl:attribute>
              <xsl:choose>
                <xsl:when test="$definedsize &lt; 60">
                  <xsl:attribute name="size">
                    <xsl:value-of select="$definedsize"/>
                  </xsl:attribute>
                  <xsl:attribute name="maxlength">
                    <xsl:value-of select="$definedsize"/>
                  </xsl:attribute>
                </xsl:when>
                <xsl:when test="$definedsize &gt;= 60">
                  <xsl:attribute name="size">
                    <xsl:value-of select="60"/>
                  </xsl:attribute>
                  <xsl:attribute name="maxlength">
                    <xsl:value-of select="$definedsize"/>
                  </xsl:attribute>
                </xsl:when>
              </xsl:choose>
              <xsl:attribute name="value">$!instance.<xsl:value-of select="@name"/></xsl:attribute>
              <xsl:attribute name="title">
                <xsl:value-of select="normalize-space( $if-missing)"/>
              </xsl:attribute>
            </input>
            <xsl:if test="string-length( $minimum) &gt; 0 and string-length( $maximum) &gt; 0">
              <div style="width:200px; height:20px; background: transparent url(../images/slider-images-track-right.png) no-repeat top right;">
                <xsl:attribute name="id">
                  <xsl:value-of select="concat( @name, '-track')"/>
                </xsl:attribute>
                <div style="position: absolute; width: 5px; height: 20px; background: transparent url(../images/slider-images-track-left.png) no-repeat top left">
                  <xsl:attribute name="id">
                    <xsl:value-of select="concat( @name, '-track-left')"/>
                  </xsl:attribute>
                </div>
                <div style="width:19px; height:20px;">
                  <xsl:attribute name="id">
                    <xsl:value-of select="concat( @name, '-slider')"/>
                  </xsl:attribute>
                  <img src="../images/slider-images-handle.png" alt="" style="float: left;" />
                </div>
              </div>
              <script type="text/javascript" language="javascript">
                // &lt;![CDATA[
                new Control.Slider('<xsl:value-of select="@name"/>-slider','<xsl:value-of select="@name"/>-track',{
                  onSlide:function(v){$('<xsl:value-of select="concat( 'instance_', @name)"/>').value = <xsl:value-of select="$minimum"/>+ Math.floor(v*(<xsl:value-of select="$maximum - $minimum"/>))}
                })
                // ]]&gt;
              </script>
            </xsl:if>
            <!-- TODO: generate javascript to do client-side validation -->
          </xsl:when>
          <xsl:when test="option">
            <!-- if a property has options, we definitely want a select widget-->
            <select>
              <xsl:attribute name="id">
                <xsl:value-of select="concat( 'instance_', @name)"/>
              </xsl:attribute>
              <xsl:attribute name="name">
                <xsl:value-of select="concat( 'instance.', @name)"/>
              </xsl:attribute>
              <xsl:attribute name="title">
                <xsl:value-of select="normalize-space( $if-missing)"/>
              </xsl:attribute>
              <xsl:apply-templates select="option"/>
            </select>
            <script type="text/javascript" language="javascript">
                #set ( <xsl:value-of select="concat( '$', @name, '_sel_opt')"/>="<xsl:value-of select="concat( @name, '-$instance.', @name)"/>")
                option = document.getElementById( "<xsl:value-of select="concat( '$', @name, '_sel_opt')"/>");

                if ( option != null)
                {
                  option.selected = true;
                }
            </script>
          </xsl:when>
          <xsl:when test="@type='boolean'">
            ${FormHelper.CheckboxField( "instance.<xsl:value-of select="@name"/>")}
          </xsl:when>
          <xsl:when test="@type='date'">
            <xsl:variable name="class"><xsl:if test="@required='true'">required </xsl:if>date-field validate-date</xsl:variable>
            ${FormHelper.TextField( "instance.<xsl:value-of select="@name"/>", "%{class='<xsl:value-of select="$class"/>' size='10' maxlength='10'}")}
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="class">
              <xsl:if test="@required='true'">required </xsl:if><xsl:choose>
                <xsl:when test="@type='integer'">validate-digits</xsl:when>
                <xsl:when test="@type='real'">validate-number</xsl:when>
                <xsl:when test="@type='money'">validate-number</xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="size">
              <xsl:choose>
                <xsl:when test="@size &lt; 60">
                  <xsl:value-of select="@size"/>
                </xsl:when>
                <xsl:when test="@type='integer'">8</xsl:when>
                <xsl:when test="@type='real'">8</xsl:when>
                <xsl:when test="@type='money'">8</xsl:when>
                <xsl:otherwise>60</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            ${FormHelper.TextField( "instance.<xsl:value-of select="@name"/>", "%{class='<xsl:value-of select="$class"/>' title='<xsl:value-of select="normalize-space( $if-missing)"/>' size='<xsl:value-of select="$size"/>' maxlength='<xsl:value-of select="@size"/>'}")}
         </xsl:otherwise>
      </xsl:choose>        
      </td>
      <td class="help">
        <xsl:apply-templates select="help[@locale = $locale]"/>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="prompt">
    <xsl:value-of select="@prompt"/>
  </xsl:template>
  
  <xsl:template match="help">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="option">
    <option>
      <xsl:attribute name="id"><xsl:value-of select="../@name"/>-<xsl:value-of select="@value"/></xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="prompt[@locale=$locale]">
          <xsl:value-of select="prompt[@locale=$locale]/@prompt"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@value"/>
        </xsl:otherwise>
      </xsl:choose>
    </option>
  </xsl:template>
    
  <!-- layout of lists -->

  <xsl:template match="list">
    <xsl:variable name="action" select="@onselect"/>
    <xsl:text>
    </xsl:text>
    <xsl:comment> [ cut here: next file '<xsl:value-of select="concat( ../@name, '/', @name)"/>.auto.vm' ] </xsl:comment>
    <xsl:text>
    </xsl:text>
    <xsl:variable name="withpluralsuffix">
      <!-- English-laguage syntactic sugar of entity name -->
      <xsl:choose>
        <xsl:when test="../@name='Person'">People</xsl:when>
        <xsl:when test="starts-with( substring(../@name, string-length(../@name) ), 's')">
          <xsl:value-of select="../@name"/>es
        </xsl:when>
        <xsl:when test="starts-with( substring(../@name, string-length(../@name) ), 'y')">
          <xsl:value-of select="substring( ../@name, 0, string-length(../@name) )"/>ies
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="../@name"/>s
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <html>
      <head>
        #set( $title = "<xsl:value-of select="normalize-space( concat( 'List ', $withpluralsuffix))"/>")
        <xsl:call-template name="head"/>
        <xsl:comment>
          Auto generated Velocity list for <xsl:value-of select="@name"/>,
          generated from ADL.

          Generated using adl2listview.xsl <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
        ${Ajax.InstallScripts()}
        ${FormHelper.InstallScripts()}
        ${Validation.InstallScripts()}
        ${Scriptaculous.InstallScripts()}
      </head>
      <body>

        <xsl:call-template name="top"/>
        <div class="content">
          <xsl:if test="@name='list'">
            <!-- this is a hack. There shouldn't be anything magic about a list named 'list'. 
          We need lists (and forms) to have some sort of pragma to guide the transformation 
          process -->
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
              <xsl:if test="../form">
                <span class="add">
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="concat( ../form[position() = 1]/@name, '.rails')"/>
                    </xsl:attribute>
                    Add a new <xsl:value-of select="../@name"/>
                  </a>
                </span>
              </xsl:if>
              <div class="search">
                <form method="get">
                  <xsl:attribute name="action">
                    <xsl:value-of select="@name"/>.rails
                  </xsl:attribute>
                  <label for="searchexpr">Search:</label>
                  <input type="text" id="searchexpr" name="searchexpr" size="12"/>
                </form>
              </div>
            </div>
          </xsl:if>
          <table>
            <xsl:choose>
              <xsl:when test="@properties='listed'">
                <tr>
                  <xsl:for-each select="field">
                    <th>
                      <xsl:variable name="pname" select="@property"/>
                      <xsl:variable name="property" select="ancestor::entity/property[@name=$pname]"/>
                      <xsl:choose>
                        <xsl:when test="$property/prompt[@locale=$locale]">
                          <xsl:value-of select="$property/prompt[@locale=$locale]/@prompt"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="@property"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </th>
                  </xsl:for-each>
                  <th>-</th>
                </tr>
                #foreach( $instance in $instances)
                #if ( $velocityCount % 2 == 0)
                #set( $oddity = "even")
                #else
                #set( $oddity = "odd")
                #end
                <tr class="$oddity">
                  <xsl:for-each select="field">
                    <td>
                      $!instance.<xsl:value-of select="@property"/>
                    </td>
                  </xsl:for-each>
                  <td>
                    <a>
                      <xsl:attribute name="href">
                        <xsl:value-of select="concat( $action, '.rails?Id=$instance.Id')"/>
                      </xsl:attribute>
                      Edit!
                    </a>
                  </td>
                </tr>
                #end
              </xsl:when>
              <xsl:otherwise>
                <tr>
                  <xsl:for-each select="ancestor::entity/property[@distinct='user']">
                    <th>
                      <xsl:choose>
                        <xsl:when test="prompt[@locale=$locale]">
                          <xsl:value-of select="prompt[@locale=$locale]/@prompt"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="@name"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </th>
                  </xsl:for-each>
                  <th>-</th>
                </tr>
                #foreach( $instance in $instances)
                #if ( $velocityCount % 2 == 0)
                #set( $oddity = "even")
                #else
                #set( $oddity = "odd")
                #end
                <tr class="$oddity">
                  <xsl:for-each select="ancestor::entity/property[@distinct='user']">
                <td>
                  $!instance.<xsl:value-of select="@name"/>
                </td>
              </xsl:for-each>
              <td>
                <a>
                  <xsl:attribute name="href">
                    <xsl:value-of select="concat( $action, '.rails?Id=$instance.Id')"/>
                  </xsl:attribute>
                  Edit!
                </a>
              </td>
            </tr>
            #end
          </xsl:otherwise>
        </xsl:choose>
      </table>
      </div>
      <xsl:call-template name="foot"/>
    </body>
    </html>
  </xsl:template>

  <!-- overall page layout -->
  
  <xsl:template name="head">
    <xsl:choose>
      <xsl:when test="head">
        <xsl:apply-templates select="head/*"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/application/content/head/*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="top">
    <xsl:choose>
      <xsl:when test="top">
        <xsl:apply-templates select="top/*"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/application/content/top/*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="foot">
    <xsl:choose>
      <xsl:when test="foot">
        <xsl:apply-templates select="foot/*"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/application/content/foot/*"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- if this node (default to current node) has a child of type prompt for the current locale, 
    show that prompt; else show the first prompt child with locale='default' if any;
    else show the value of the fallback param -->
  <xsl:template name="showprompt">
    <xsl:param name="fallback" select="Unknown"/>
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node/prompt[@locale=$locale]">
        <xsl:value-of select="$node/prompt[@locale=$locale][1]/@prompt"/>
      </xsl:when>
      <xsl:when test="$node/prompt[@locale='default']">
        <xsl:value-of select="$node/prompt[@locale='default'][1]/@prompt"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$fallback"/>
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