<?xml version="1.0" encoding="UTF-8" ?>
  <xsl:stylesheet version="1.0"
  xmlns="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!--
    Application Description Language framework
    adl2views.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into velocity view templates
    
    $Author: sb $
    $Revision: 1.12 $
    $Date: 2008-03-19 15:37:48 $
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
    
  <!-- whether or not to auto-generate site navigation - by default, don't -->
  <xsl:param name="generate-site-navigation"/>

  <!-- the current state of play is that we can only generate views with permissions for one group. 
      TODO: this isn't how it's supposed to be. It's supposed to be that at service time the system 
      checks which groups the current user is member of, and renders each widget with the most relaxed 
      permissions applicable to that user - but we don't yet have the parts in place to do that.
      This variable selects which group's permissions should be used when generating widgets -->
  <xsl:param name="permissions-group" select="public"/>

  <!-- what's all this about? the objective is to get the revision number of the 
    transform into the output, /without/ getting that revision number overwritten 
    with the revision number of the generated file when the generated file is 
    stored to CVS -->

  <xsl:variable name="transform-rev1"
                select="substring( '$Revision: 1.12 $', 11)"/>
  <xsl:variable name="transform-revision"
                select="substring( $transform-rev1, 0, string-length( $transform-rev1) - 1)"/>


  <xsl:template match="adl:application">
    <output>
      <xsl:apply-templates select="adl:entity"/>
      <!-- make sure extraneous junk doesn't get into the last file generated,
      by putting it into a separate file -->
      <xsl:comment> [ cut here: next file 'tail.txt' ] </xsl:comment>
    </output>
  </xsl:template>

  <xsl:template match="adl:entity[@foreign='true']"/>
  <!-- Don't bother generating anything for foreign entities -->

  <xsl:template match="adl:entity">
    <xsl:variable name="keyfield">
      <xsl:choose>
        <xsl:when test="adl:key/adl:property">
          <xsl:value-of select="adl:key/adl:property[position()=1]/@name"/>
        </xsl:when>
        <xsl:otherwise>[none]</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:apply-templates select="adl:form"/>
    <xsl:apply-templates select="adl:list"/>
    <xsl:text>
    </xsl:text>
    <xsl:comment> [ cut here: next file '<xsl:value-of select="concat( @name, '/maybedelete.auto.vm')"/>' ] </xsl:comment>
    <xsl:text>
    </xsl:text>
    <html>
        #set( $title = "<xsl:value-of select="concat( 'Really delete ', @name)"/> $instance.UserIdentifier")
      <head>
        <title>$!title</title>
        <xsl:call-template name="head"/>
        <xsl:comment>
          Auto generated Velocity maybe-delete form for <xsl:value-of select="@name"/>,
          generated from ADL.

          Generated using adl2views.xslt <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
        ${ShuffleWidgetHelper.InstallScripts()}
        ${Ajax.InstallScripts()}
        ${FormHelper.InstallScripts()}
        ${Validation.InstallScripts()}
        ${Scriptaculous.InstallScripts()}

        ${ScriptsHelper.InstallScript( "Behaviour")}
        ${ScriptsHelper.InstallScript( "Sitewide")}
      </head>
      <body>
        <xsl:call-template name="top"/>
        <form action="delete.rails" method="post">
          <xsl:for-each select="adl:key/adl:property">
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

  <xsl:template match="adl:form">
    <xsl:variable name="formname" select="@name"/>
    <xsl:variable name="aoran">
      <xsl:variable name="initial" select="substring( ancestor::adl:entity/@name, 1, 1)"/>
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
    <xsl:comment> [ cut here: next file '<xsl:value-of select="concat( ancestor::adl:entity/@name, '/', @name)"/>.auto.vm' ] </xsl:comment>
    <xsl:text>
    </xsl:text>
    <html>
      <xsl:comment>
        #if ( $instance)
        #set( $title = "<xsl:value-of select="concat( 'Edit ', ' ', ancestor::adl:entity/@name)"/> $instance.UserIdentifier")
        #else
        #set( $title = "Add a new <xsl:value-of select="ancestor::adl:entity/@name"/>")
        #end
      </xsl:comment>
      <head>
        <title>$!title</title>
        <xsl:call-template name="head"/>
        <xsl:comment>
          Application Description Language framework

          Auto generated Velocity form for <xsl:value-of select="ancestor::adl:entity/@name"/>,
          generated from ADL.

          Generated using adl2views.xsl <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
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

        <script type='text/javascript' language='JavaScript1.2'>
          var panes = new Array( <xsl:for-each select='adl:fieldgroup'>
            "<xsl:value-of select='@name'/>"<xsl:choose>
              <xsl:when test="position() = last()"/>
              <xsl:otherwise>,</xsl:otherwise>
            </xsl:choose>
          </xsl:for-each> );

          var siteRoot = '$siteRoot';

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
          <xsl:for-each select="//definition">
            <xsl:variable name="errormsg">
              <xsl:choose>
                <xsl:when test="adl:help[@locale=$locale]">
                  <xsl:apply-templates select="adl:help[@locale=$locale]"/>
                </xsl:when>
                <xsl:otherwise>
                  Does not meet the format requirements for <xsl:value-of select="@name"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
          Validation.add( '<xsl:value-of select="concat('validate-custom-', @name)"/>',
            '<xsl:value-of select="normalize-space( $errormsg)"/>',
            {
            <xsl:choose>
              <xsl:when test="@pattern">
                pattern : new RegExp("<xsl:value-of select="@pattern"/>","gi")<xsl:if test="@size">,
                maxLength : <xsl:value-of select="@size"/>
                </xsl:if>                                                                      
              </xsl:when>
              <xsl:when test="@minimum">
                min : <xsl:value-of select="@minimum"/><xsl:if test="@maximum">,
                max : <xsl:value-of select="@maximum"/>
                </xsl:if>
              </xsl:when>
            </xsl:choose>
            });
          </xsl:for-each>

        </script>

        ${StylesHelper.InstallStylesheet( "Epoch")}

        <script type="text/javascript" language='JavaScript1.2' src="../script/panes.js"></script>

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
        <div class="content">
          #if ( $errors)
          #if ( $errors.Count != 0)
          <ul class="errors">
            #foreach( $e in $errors)
            <li>$t.Enc($e)</li>
            #end
          </ul>
          #end
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
            <xsl:variable name="form" select="."/>
            <xsl:for-each select="ancestor::adl:entity/adl:key/adl:property">
              <xsl:variable name="keyname" select="@name"/>
              <xsl:choose>
                <xsl:when test="$form/adl:field[@property=$keyname]">
                  <!-- it's already a field of the form - no need to add a hidden one -->
                </xsl:when>
                <xsl:otherwise>
                  <!-- create a hidden widget for the natural primary key -->
                  ${FormHelper.HiddenField( "instance.<xsl:value-of select="$keyname"/>")}
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each> 
            <xsl:if test="adl:fieldgroup">
              <div id="tabbar">
                <xsl:for-each select="adl:fieldgroup">
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
            <xsl:apply-templates select="adl:fieldgroup"/>
            <div class="pane">
              <table>
                <xsl:choose>
                  <xsl:when test="@properties='listed'">
                    <xsl:apply-templates select="adl:field|adl:auxlist|adl:verb"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="ancestor::adl:entity/adl:property"/>
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
                    #if ( $instance.NoDeleteReason)
                      [ $instance.NoDeleteReason ]
                    #else
                      To delete this record
                    #end
                  </td>
                  <td class="actionDangerous" style="text-align:right">
                    #if ( $instance.NoDeleteReason)
                    <button type="submit" disabled="disabled" title="$instance.NoDeleteReason"  name="command" value="delete">Delete this!</button>
                    #else
                    <button type="submit" name="command" value="delete">Delete this!</button>
                    #end
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

  <xsl:template match="adl:fieldgroup">
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
    <xsl:comment>
      $listprop = <xsl:value-of select="$listprop"/>;
      $farent = <xsl:value-of select="$farent"/>;
      $nearent = <xsl:value-of select="$nearent"/>;
      $farid = <xsl:value-of select="$farid"/>;
      $farkey = <xsl:value-of select="$farkey"/>;
      $nearkey = <xsl:value-of select="$nearkey"/>;
    </xsl:comment>
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
          <xsl:for-each select="adl:field">
            <xsl:variable name="fieldprop" select="@property"/>
            <th>
              <!-- Getting the prompt for the field from a property of another entity is a bit 
                complex... -->
              <xsl:call-template name="showprompt">
                <xsl:with-param name="node" select="//adl:entity[@name=$farent]//adl:property[@name=$fieldprop]"/>
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
          <xsl:for-each select="adl:field">
            <xsl:variable name="fieldprop" select="@property"/>
            <td>
              <xsl:choose>
                <xsl:when test="//adl:entity[@name=$farent]//adl:property[@name=$fieldprop]/@type='entity'">
                  #if ( $item.<xsl:value-of select="@property"/>)
                  $item.<xsl:value-of select="@property"/>.UserIdentifier
                  #end
                </xsl:when>
                <xsl:when test="//adl:entity[@name=$farent]//adl:property[@name=$fieldprop]/adl:option">
                  <!-- if we can get a prompt value for the option, it would be better to 
                  show it than the raw value-->
                  <xsl:for-each select="//adl:entity[@name=$farent]//adl:property[@name=$fieldprop]/adl:option">
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
        <!-- properties not listed, so therefore presumably all. -->
        <tr>
          <xsl:for-each select="//adl:entity[@name=$farent]//adl:property[@distinct='user']">
            <th>
              <xsl:choose>
                <xsl:when test="adl:prompt[@locale=$locale]">
                  <xsl:value-of select="adl:prompt[@locale=$locale]/@prompt"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@name"/>
                </xsl:otherwise>
              </xsl:choose>
            </th>
          </xsl:for-each>
          <th>-</th>
        </tr>
        #foreach( $item in $instance.<xsl:value-of select="@property"/>)
        #if ( $velocityCount % 2 == 0)
        #set( $oddity = "even")
        #else
        #set( $oddity = "odd")
        #end
        <tr class="$oddity">
          <xsl:for-each select="//adl:entity[@name=$farent]//adl:property[@distinct='user']">
            <td>
              <xsl:variable name="fieldprop" select="@name"/>
              <xsl:choose>
                <xsl:when test="@type='entity'">
                  #if ( $item.<xsl:value-of select="@name"/>)
                  $item.<xsl:value-of select="@name"/>.UserIdentifier
                  #end
                </xsl:when>
                <xsl:when test="adl:option">
                  <!-- if we can get a prompt value for the option, it would be better to 
                  show it than the raw value-->
                  <xsl:for-each select="adl:option">
                    #if ( $item.<xsl:value-of select="$fieldprop"/> == '<xsl:value-of select="@value"/>')
                    <xsl:call-template name="showprompt">
                      <xsl:with-param name="fallback" select="@value"/>
                    </xsl:call-template>
                    #end
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  $!item.<xsl:value-of select="@name"/>
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
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="adl:verb">
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
        <xsl:comment>Computed field (<xsl:value-of select="$propname"/>)? TODO: Not yet implememented</xsl:comment>
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
          <xsl:with-param name="fallback" select="@name"/>
        </xsl:call-template>")}
      </td>
      <td class="widget" colspan="2">
        #if( $instance)
        <xsl:value-of select="concat( '$t.Msg( $instance.', @name, ')')"/>
        $FormHelper.HiddenField( "instance.<xsl:value-of select="@name"/>")
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
  
  <xsl:template match="adl:property[@type='link']">
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
        <xsl:apply-templates select="adl:help[@locale = $locale]"/>
      </td>
    </tr>
  </xsl:template>


  <xsl:template match="adl:property[@type='text']">
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
          <xsl:when test="adl:prompt[@locale = $locale]">
            <xsl:apply-templates select="adl:prompt[@locale = $locale]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@name"/>
          </xsl:otherwise>
        </xsl:choose>")}
      </td>
      <td class="widget" colspan="2">
        ${FormHelper.TextArea( "instance.<xsl:value-of select="@name"/>", "%{rows='8', cols='60', title='<xsl:value-of select="$if-missing"/>'}")}
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
    <!-- TODO: This really needs to be refactored -->
    <!-- TODO: we really need to be able to handle different permissions for different 
    groups. If the current user is not a member of a group which has read access to 
    this widget, the widget shouldn't even appear (unless they have write but not read?); 
    if they are not a member of a group which has write access, the widget should be 
    disabled. I don't have time to implement this now as it is not trivial, but it is 
    important! -->
    <!-- TODO: this is a one-database-role permission model, because that's all SRU needs. 
        Different permissions for different database groups is much more complex! Also, this 
        handles permissions on only properties and entities, not on forms. Perhaps we need a 
        Helper class? -->
    <xsl:variable name="permission">
      <xsl:call-template name="property-permission">
        <xsl:with-param name="property" select="."/>
        <xsl:with-param name="groupname" select ="$permissions-group"/>
      </xsl:call-template>
    </xsl:variable>
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
        <xsl:choose>
          <xsl:when test="$permission='none'">
            [You are not authorised to see this data]
          </xsl:when>
          <xsl:when test="$permission='read'">
            <xsl:choose>
              <xsl:when test="@type='entity'">
                <xsl:value-of select="concat('$instance.', @name, '.UserIdentifier')"/>
                ${FormHelper.HiddenField( <xsl:value-of select="concat('$instance.', @name, '.KeyString')"/>)}
              </xsl:when>
              <!-- TODO: if @type='list' or 'link', should generate Velocity to generate ul list
                of UserIdentifiers
              -->
              <xsl:otherwise>
                <xsl:value-of select="concat('$instance.', @name)"/>
                ${FormHelper.HiddenField( <xsl:value-of select="concat('$instance.', @name)"/>)}
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$permission='insert' or $permission='noedit'">
            #if ($instance.<xsl:value-of select="@name"/>)
            <xsl:choose>
              <xsl:when test="@type='entity'">
                <xsl:value-of select="concat('$instance.', @name, '.UserIdentifier')"/>
                ${FormHelper.HiddenField( <xsl:value-of select="concat('$instance.', @name, '.KeyString')"/>)}
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('$instance.', @name)"/>
                ${FormHelper.HiddenField( <xsl:value-of select="concat('$instance.', @name)"/>)}
              </xsl:otherwise>
            </xsl:choose>
            #else
            <xsl:call-template name="widget">
              <xsl:with-param name="property" select="."/>
            </xsl:call-template>
            #end
          </xsl:when>
          <!-- TODO: if $permission='insert', then you should get an editable widget if there 
          is no current value, else a 'not authorised' message -->
          <!-- TODO: if $permission='noedit', then you should get an editable widget if there 
          is no current value, else just the value -->
          <xsl:otherwise>
            <xsl:call-template name="widget">
              <xsl:with-param name="property" select="."/>
            </xsl:call-template>
          </xsl:otherwise>
      </xsl:choose>        
      </td>
      <td class="help">
        <xsl:apply-templates select="adl:help[@locale = $locale]"/>
      </td>
    </tr>
    </xsl:if>
  </xsl:template>

    <!-- render an appropriate widget for the indicated property 
      property: a property element
    -->
    <xsl:template name="widget">
      <xsl:param name="property"/>
      <xsl:variable name="if-missing">
        <xsl:choose>
          <xsl:when test="adl:if-missing[@locale = $locale]">
            <xsl:value-of select="adl:if-missing[@locale = $locale]"/>
          </xsl:when>
          <xsl:when test="$property/@required='true'">
            You must provide a value for <xsl:value-of select="$property/@name"/>
          </xsl:when>
          <xsl:when test="$property/@type='defined'">
            The value for <xsl:value-of select="$property/@name"/> must be <xsl:value-of select="$property/@definition"/>
          </xsl:when>
          <xsl:when test="$property/@type='entity'">
            The value for <xsl:value-of select="$property/@name"/> must be an instance of <xsl:value-of select="$property/@entity"/>
          </xsl:when>
          <xsl:otherwise>
            The value for <xsl:value-of select="$property/@name"/> must be <xsl:value-of select="$property/@type"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
      <xsl:when test="$property/@type='entity'">
        <!-- a menu of the appropriate entity -->
        <xsl:choose>
          <xsl:when test="$property/@required='true'">
            <!-- if required='true', then you should not get the firstoption stuff -->
            #if ( $instance)
            ${FormHelper.Select( "instance.<xsl:value-of select="$property/@name"/>", $instance.<xsl:value-of select="$property/@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{text='UserIdentifier', value='KeyString', title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #else
            ${FormHelper.Select( "instance.<xsl:value-of select="$property/@name"/>", $<xsl:value-of select="$property/@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{text='UserIdentifier', value='KeyString', title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #end
          </xsl:when>
          <xsl:otherwise>
            #if ( $instance)
            ${FormHelper.Select( "instance.<xsl:value-of select="$property/@name"/>", $instance.<xsl:value-of select="$property/@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{firstoption='[unset]', firstoptionvalue='-1', text='UserIdentifier', value='KeyString', title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #else
            ${FormHelper.Select( "instance.<xsl:value-of select="$property/@name"/>", $<xsl:value-of select="$property/@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{firstoption='[unset]', firstoptionvalue='-1', text='UserIdentifier', value='KeyString', title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
            #end
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$property/@type='list'">
        <!-- a multi-select menu of the appropriate entity -->
        ${FormHelper.Select( "instance.<xsl:value-of select="$property/@name"/>", $instance.<xsl:value-of select="$property/@name"/>, <xsl:value-of select="concat( '$all_', @name)"/>, "%{multiple='multiple', size='8', text='UserIdentifier', value='KeyString', title='<xsl:value-of select="normalize-space( $if-missing)"/>'}" )}
      </xsl:when>
      <xsl:when test="$property/@type='defined'">
        <!-- likely to be hardest of all... -->
        <xsl:variable name="definition">
          <xsl:value-of select="$property/@definition"/>
        </xsl:variable>
        <xsl:variable name="maximum">
          <xsl:value-of select="//adl:definition[@name=$definition]/@maximum"/>
        </xsl:variable>
        <xsl:variable name="minimum">
          <xsl:value-of select="//adl:definition[@name=$definition]/@minimum"/>
        </xsl:variable>
        <xsl:variable name="validationpattern">
          <xsl:value-of select="//adl:definition[@name=$definition]/@pattern"/>
        </xsl:variable>
        <xsl:variable name="definedtype">
          <xsl:value-of select="//adl:definition[@name=$definition]/@type"/>
        </xsl:variable>
        <xsl:variable name="definedsize">
          <xsl:value-of select="//adl:definition[@name=$definition]/@size"/>
        </xsl:variable>
        <input type="text">
          <xsl:variable name="cssclass">
            <xsl:if test="$property/@required='true'">required </xsl:if>
            <xsl:choose>
              <xsl:when test="//adl:definition[@name=$definition]/@pattern">
                <xsl:value-of select="concat( 'validate-custom-', $definition)"/>
              </xsl:when>
              <xsl:when test="//adl:definition[@name=$definition]/@minimum">
                <xsl:value-of select="concat( 'validate-custom-', $definition)"/>
              </xsl:when>
              <xsl:when test="$definedtype='integer'">validate-digits</xsl:when>
              <xsl:when test="$definedtype='real'">validate-number</xsl:when>
              <xsl:when test="$definedtype='money'">validate-number</xsl:when>
              <xsl:when test="$definedtype='date'">date-field validate-date</xsl:when>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="class">
            <xsl:value-of select="normalize-space( cssclass)"/>
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
          <xsl:attribute name="value">
            $!instance.<xsl:value-of select="$property/@name"/>
          </xsl:attribute>
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
            new Control.Slider('<xsl:value-of select="$property/@name"/>-slider','<xsl:value-of select="$property/@name"/>-track',{
            onSlide:function(v){$('<xsl:value-of select="concat( 'instance_', @name)"/>').value = <xsl:value-of select="$minimum"/>+ Math.floor(v*(<xsl:value-of select="$maximum - $minimum"/>))}
            })
            // ]]&gt;
          </script>
        </xsl:if>
        <!-- TODO: generate javascript to do client-side validation -->
      </xsl:when>
      <xsl:when test="adl:option">
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
          <xsl:apply-templates select="adl:option"/>
        </select>
        <script type="text/javascript" language="javascript">
          // &lt;![CDATA[
          #set ( <xsl:value-of select="concat( '$', @name, '_sel_opt')"/>="<xsl:value-of select="concat( @name, '-$instance.', @name)"/>")
          option = document.getElementById( "<xsl:value-of select="concat( '$', @name, '_sel_opt')"/>");

          if ( option != null)
          {
          option.selected = true;
          }
          // ]]&gt;
        </script>
      </xsl:when>
      <xsl:when test="$property/@type='boolean'">
        ${FormHelper.CheckboxField( "instance.<xsl:value-of select="$property/@name"/>")}
      </xsl:when>
      <xsl:when test="$property/@type='date'">
        <xsl:variable name="class">
          <xsl:if test="$property/@required='true'">required </xsl:if>date-field validate-date
        </xsl:variable>
        ${FormHelper.TextField( "instance.<xsl:value-of select="$property/@name"/>", "%{class='<xsl:value-of select="normalize-space( $class)"/>', textformat='d', size='10', maxlength='10'}")}
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="class">
          <xsl:if test="$property/@required='true'">required </xsl:if>
          <xsl:choose>
            <xsl:when test="$property/@type='integer'">validate-digits</xsl:when>
            <xsl:when test="$property/@type='real'">validate-number</xsl:when>
            <xsl:when test="$property/@type='money'">validate-number</xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="size">
          <xsl:choose>
            <xsl:when test="$property/@size &lt; 60">
              <xsl:value-of select="$property/@size"/>
            </xsl:when>
            <xsl:when test="$property/@type='integer'">8</xsl:when>
            <xsl:when test="$property/@type='real'">8</xsl:when>
            <xsl:when test="$property/@type='money'">8</xsl:when>
            <xsl:otherwise>60</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="maxlength">
          <xsl:choose>
            <xsl:when test="$property/@size &gt;= 60">
              <xsl:value-of select="$property/@size"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$size"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        ${FormHelper.TextField( "instance.<xsl:value-of select="$property/@name"/>", "%{class='<xsl:value-of select="$class"/>', title='<xsl:value-of select="normalize-space( $if-missing)"/>', size='<xsl:value-of select="$size"/>', maxlength='<xsl:value-of select="$maxlength"/>'}")}
      </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

  <xsl:template match="adl:prompt">
    <xsl:value-of select="@prompt"/>
  </xsl:template>
  
  <xsl:template match="adl:help">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="adl:option">
    <option>
      <xsl:attribute name="id"><xsl:value-of select="../@name"/>-<xsl:value-of select="@value"/></xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="adl:prompt[@locale=$locale]">
          <xsl:value-of select="adl:prompt[@locale=$locale]/@prompt"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@value"/>
        </xsl:otherwise>
      </xsl:choose>
    </option>
  </xsl:template>
    
  <!-- layout of lists -->

  <xsl:template match="adl:list">
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
        <title>$!title</title>
        <xsl:call-template name="head"/>
        <xsl:comment>
          Auto generated Velocity list for <xsl:value-of select="ancestor::adl:entity/@name"/>,
          generated from ADL.

          Generated using adl2listview.xsl <xsl:value-of select="$transform-revision"/>
        </xsl:comment>
        ${Ajax.InstallScripts()}
        ${FormHelper.InstallScripts()}
        ${Validation.InstallScripts()}
        ${Scriptaculous.InstallScripts()}
        ${DateTimeHelper.InstallScripts()}

        ${ScriptsHelper.InstallScript( "Behaviour")}
        ${ScriptsHelper.InstallScript( "Sitewide")}
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
              <xsl:if test="../adl:form">
                <span class="add">
                  <a>
                    <xsl:attribute name="href">
                      <xsl:value-of select="concat( ancestor::adl:entity/adl:form[position()=1]/@name, '.rails')"/>
                    </xsl:attribute>
                    Add a new <xsl:value-of select="ancestor::adl:entity/@name"/>
                  </a>
                </span>
              </xsl:if>
              <!-- div class="search">
                <form method="get">
                  <xsl:attribute name="action">
                    <xsl:value-of select="@name"/>.rails
                  </xsl:attribute>
                  <label for="searchexpr">Search:</label>
                  <input type="text" id="searchexpr" name="searchexpr" size="12"/>
                </form>
              </div -->
            </div>
          </xsl:if>
          <table>
            <xsl:choose>
              <xsl:when test="@properties='listed'">
                <tr>
                  <xsl:for-each select="adl:field">
                    <th>
                      <xsl:variable name="pname" select="@property"/>
                      <xsl:variable name="property" select="ancestor::adl:entity//adl:property[@name=$pname]"/>
                      <xsl:choose>
                        <xsl:when test="$property/adl:prompt[@locale=$locale]">
                          <xsl:value-of select="$property/adl:prompt[@locale=$locale]/@prompt"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="@property"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </th>
                  </xsl:for-each>
                  <xsl:for-each select="ancestor::adl:entity/adl:form">
                    <th>-</th>
                  </xsl:for-each>
                </tr>
                #foreach( $instance in $instances)
                #if ( $velocityCount % 2 == 0)
                #set( $oddity = "even")
                #else
                #set( $oddity = "odd")
                #end
                <tr class="$oddity">
                  <xsl:for-each select="adl:field">
                    <td>
                      <xsl:variable name="prop" select="@property"/>
                      <xsl:choose>
                        <xsl:when test="ancestor::adl:entity//adl:property[@name=$prop]/@type = 'date'">
                          #if ( $instance.<xsl:value-of select="@property"/>)
                            $instance.<xsl:value-of select="@property"/>.ToString( 'd')
                          #end
                        </xsl:when>
                        <xsl:when test="ancestor::adl:entity//adl:property[@name=$prop]/@type='message'">
                          #if ( $instance.<xsl:value-of select="$prop"/>)
                          $t.Msg( $instance.<xsl:value-of select="$prop"/>)
                          #end
                        </xsl:when>
                        <xsl:when test="ancestor::adl:entity//adl:property[@name=$prop]/@type='entity'">
                          #if( $instance.<xsl:value-of select="$prop"/>)
                          $instance.<xsl:value-of select="$prop"/>.UserIdentifier
                          #end
                        </xsl:when>
                        <xsl:otherwise>
                          $!instance.<xsl:value-of select="$prop"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </xsl:for-each>
                  <xsl:variable name="keys">
                    <!-- assemble keys in a Velocity-friendly format, then splice it into
                    the HREF below -->
                    <xsl:for-each select="ancestor::adl:entity/adl:key/adl:property">
                      <xsl:variable name="sep">
                        <xsl:choose>
                          <xsl:when test="position()=1">?</xsl:when>
                          <xsl:otherwise>&amp;</xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <xsl:choose>
                        <xsl:when test="@type='entity'">
                          <xsl:value-of select="concat( $sep, @name, '_Value=$instance.', @name, '_Value')"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat( $sep, @name, '=$instance.', @name)"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:for-each select="ancestor::adl:entity/adl:form">
                    <!-- by default create a link to each form declared for the entity. 
                    We probably need a means of overriding this -->
                    <td>
                      <a>
                        <xsl:attribute name="href">
                          <xsl:value-of select="concat( @name, '.rails', $keys)"/>
                        </xsl:attribute>
                        <xsl:value-of select="@name"/>!
                      </a>
                    </td>
                  </xsl:for-each>
                </tr>
                #end <!-- of iteration foreach( $instance in $instances) -->
              </xsl:when> <!-- close of @properties='listed ' -->
              <xsl:otherwise>
                <!-- properties are not 'listed' -->
                <tr>
                  <xsl:for-each select="ancestor::adl:entity//adl:property[@distinct='user' and not( @type='link' or @type='list')]">
                    <th>
                      <xsl:choose>
                        <xsl:when test="adl:prompt[@locale=$locale]">
                          <xsl:value-of select="adl:prompt[@locale=$locale]/@prompt"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="@name"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </th>
                  </xsl:for-each>
                  <xsl:for-each select="ancestor::adl:entity/adl:form">
                    <th>-</th>
                  </xsl:for-each>
                </tr>
                #foreach( $instance in $instances)
                #if ( $velocityCount % 2 == 0)
                #set( $oddity = "even")
                #else
                #set( $oddity = "odd")
                #end
                <tr class="$oddity">
                  <xsl:for-each select="ancestor::adl:entity//adl:property[@distinct='user']">
                    <td>
                      <xsl:choose>
                        <xsl:when test="@type = 'date'">
                          #if ( $instance.<xsl:value-of select="@name"/>)
                          $instance.<xsl:value-of select="@name"/>.ToString( 'd')
                          #end
                        </xsl:when>
                        <xsl:when test="@type='message'">
                          #if ( $instance.<xsl:value-of select="@name"/>)
                          $t.Msg( $instance.<xsl:value-of select="@name"/>)
                          #end
                        </xsl:when>
                        <xsl:when test="@type='entity'">
                          #if( $instance.<xsl:value-of select="@name"/>)
                          $instance.<xsl:value-of select="@name"/>.UserIdentifier
                          #end
                        </xsl:when>
                        <xsl:otherwise>
                          $!instance.<xsl:value-of select="@name"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </xsl:for-each>
                  <xsl:variable name="keys">
                    <!-- assemble keys in a Velocity-friendly format, then splice it into
                    the HREF below -->
                    <xsl:for-each select="ancestor::adl:entity/adl:key/adl:property">
                      <xsl:variable name="sep">
                        <xsl:choose>
                          <xsl:when test="position()=1">?</xsl:when>
                          <xsl:otherwise>&amp;</xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <xsl:choose>
                        <xsl:when test="@type='entity'">
                          <xsl:value-of select="concat( $sep, @name, '_Value=$instance.', @name, '_Value')"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat( $sep, @name, '=$instance.', @name)"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:variable>
                  <xsl:for-each select="ancestor::adl:entity/adl:form">
                    <!-- by default create a link to each form declared for the entity. 
                    We probably need a means of overriding this -->
                    <td>
                      <a>
                        <xsl:attribute name="href">
                          <xsl:value-of select="concat( @name, '.rails?', $keys)"/>
                        </xsl:attribute>
                        <xsl:value-of select="@name"/>!
                      </a>
                    </td>
                  </xsl:for-each>
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

  <xsl:template match="adl:content"/>
  
  <xsl:template name="head">
    <xsl:choose>
      <xsl:when test="adl:head">
        <xsl:for-each select="adl:head/*">
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:head/*">
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="top">
    <xsl:choose>
      <xsl:when test="adl:top">
        <xsl:for-each select="adl:top/*">
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:top/*">
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="$generate-site-navigation">
      <ul class="generatednav">
        <xsl:for-each select="//adl:entity[adl:list[@name='list']]">
          <li>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="concat( '$siteRoot', '/auto/', @name, '/', adl:list[position()=1]/@name, '.rails')"/>
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
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="//adl:content/adl:foot/*">
          <xsl:copy-of select="."/>
        </xsl:for-each>
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
      <xsl:when test="$node/adl:prompt[@locale=$locale]">
        <xsl:value-of select="$node/adl:prompt[@locale=$locale][1]/@prompt"/>
      </xsl:when>
      <xsl:when test="$node/adl:prompt[@locale='default']">
        <xsl:value-of select="$node/adl:prompt[@locale='default'][1]/@prompt"/>
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
      <xsl:param name="groupname" select="public"/>
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