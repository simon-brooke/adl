<?xml version="1.0" encoding="UTF-8" ?>  
  <!--
    Application Description Language framework
    adl2entityclass.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into entity classes
    
    $Author: sb $
    $Revision: 1.10 $
    $Date: 2008-03-05 11:05:12 $
  -->

  <!-- WARNING WARNING WARNING: Do NOT reformat this file! 
     Whitespace (or lack of it) is significant! -->
<xsl:stylesheet version="1.0"  
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:exsl="http://exslt.org/common"
  xmlns:adl="http://cygnets.co.uk/schemas/adl-1.2"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt">

  <xsl:include href="csharp-type-include.xslt"/>

  <xsl:output encoding="UTF-8" method="text"/>

  <!-- The locale for which these entities are generated 
      TODO: Entities should NOT be locale specific. Instead, the
      entity should generate messages based on the 
      client's locale. However, there may still need to be a concept of a
      'default locale', for when we don't have messages which suit the
      client's locale -->
  <xsl:param name="locale" select="en-UK"/>

  <!-- 
      The convention to use for naming auto-generated abstract primary keys. Known values are
      Id - the autogenerated primary key, if any, is called just 'Id'
      Name - the autogenerated primary key has the same name as the entity
      NameId - the name of the auto generated primary key is the name of the entity followed by 'Id'
      Name_Id - the name of the auto generated primary key is the name of the entity followed by '_Id'  
    -->
  <xsl:param name="abstract-key-name-convention" select="Id"/>

  <!-- The C# namespace within which I shall generate controllers -->
  <xsl:param name="controllerns" select="Unset"/>

  <!-- The C# namespace within which I shall generate entities -->
  <xsl:param name="entityns" select="Unset"/>

  <xsl:template match="adl:application">
    <xsl:apply-templates select="adl:entity"/>
  </xsl:template>

  <!-- Don't bother generating anything for foreign entities -->
  <xsl:template match="adl:entity[@foreign='true']"/>

  <xsl:template match="adl:entity">
    <!-- what's all this about? the objective is to get the revision number of the 
    transform into the output, /without/ getting that revision number overwritten 
    with the revision number of the generated file if the generated file is 
    stored to CVS -->

    <xsl:variable name="transform-rev1"
                  select="substring( '$Revision: 1.10 $', 11)"/>
    <xsl:variable name="transform-revision"
                  select="substring( $transform-rev1, 0, string-length( $transform-rev1) - 1)"/>

    <xsl:variable name="keyfield">
      <xsl:choose>
        <xsl:when test="$abstract-key-name-convention='Name'">
          <xsl:value-of select="@name"/>
        </xsl:when>
        <xsl:when test="$abstract-key-name-convention = 'NameId'">
          <xsl:value-of select="concat( @name, 'Id')"/>
        </xsl:when>
        <xsl:when test="$abstract-key-name-convention = 'Name_Id'">
          <xsl:value-of select="concat( @name, '_Id')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'Id'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    /* ---- [ cut here: next file '<xsl:value-of select="@name"/>.auto.cs'] ---------------- */

    //-------------------------------------------------------------
    //
    //  Application Description Language framework
    //  <xsl:value-of select="@name"/>.auto.cs
    //
    //  (c)2007 Cygnet Solutions Ltd
    //
    //  Automatically generated from application description using
    //  adl2entityclass.xsl revision <xsl:value-of select="$transform-revision"/>
    //
    //  This file is automatically generated; DO NOT EDIT IT.
    //
    //-------------------------------------------------------------
    namespace <xsl:value-of select="$entityns"/>
    {
      using System;
      using System.Configuration;
      using System.Collections;
      using System.Collections.Generic;
      using System.Text;
      using System.Text.RegularExpressions;
      using Cygnet.Exceptions;
      using Cygnet.Entities;
      using Iesi.Collections.Generic;

      /// &lt;summary&gt;
      /// <xsl:value-of select="normalize-space( adl:documentation)"/>
      /// &lt;/summary&gt;
      /// &lt;remarks&gt;
      /// Automatically generated from description of entity <xsl:value-of select="@name"/>
      /// using adl2entityclass.xsl revision <xsl:value-of select="$transform-revision"/>.
      /// Note that manually maintained parts of this class may be defined in 
      /// a separate file called <xsl:value-of select="@name"/>.manual.cs, q.v.
      ///
      /// DO NOT EDIT THIS FILE!
      /// &lt;/remarks&gt;
      public partial class <xsl:value-of select="@name"/> : Entity
      {
        /// &lt;summary&gt;
        /// Auto-generated no-args constructor; does nothing (but probably should
        /// ensure ID slot is initialised correctly)
        /// &lt;/summary&gt;
        public <xsl:value-of select="@name"/>() : base(){
        <xsl:call-template name="initialise-lists"/>
        }


        <xsl:choose>
          <xsl:when test="@natural-key">
        /* natural primary key exists - not generating abstract key */
          </xsl:when>
          <xsl:when test="adl:key">
        /* primary key exists - not generating abstract key */
        
        /// &lt;summary&gt;
        /// Auto-generated constructor; initialises each of the slots within 
        /// the primary key and also all one-to-many and many-to-many slots
        /// &lt;/summary&gt;
        public <xsl:value-of select="@name"/>( <xsl:for-each select="adl:key/adl:property">
              <xsl:variable name="csharp-type">
                <xsl:call-template name="csharp-type">
                  <xsl:with-param name="property" select="."/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:value-of select="concat( $csharp-type, ' ', @name)"/>
              <xsl:if test="not( position() = last())">, </xsl:if>
            </xsl:for-each>){
            <xsl:call-template name="initialise-lists"/>

            <xsl:for-each select="adl:key/adl:property">
          this.<xsl:value-of select="@name"/> = <xsl:value-of select="@name"/>;
            </xsl:for-each>
        }
        
          </xsl:when>
          <xsl:otherwise>
        /// &lt;summary&gt;
        /// Auto-generated one-arg constructor; initialises Id slot and also all 
        /// one-to-many slots
        /// &lt;/summary&gt;
        public <xsl:value-of select="@name"/>( int key)
        {
        <xsl:call-template name="initialise-lists"/>

           <xsl:value-of select="concat( ' _', $keyfield)"/> = key;
        }
        /// &lt;summary&gt;
        /// Auto-generated iv for Id (abstract primary key) slot
        /// &lt;/summary&gt;
        private int <xsl:value-of select="concat( ' _', $keyfield)"/> = -1;

        /// &lt;summary&gt;
        /// Auto-generated property for Id (abstract primary key) slot
        /// &lt;/summary&gt;
        public virtual int <xsl:value-of select="$keyfield"/>
        {
          get { return <xsl:value-of select="concat( ' _', $keyfield)"/>; }
          set { <xsl:value-of select="concat( ' _', $keyfield)"/> = value; }
        }
        
        /// &lt;summary&gt;
        /// Auto-generated overridden property for the Key slot, maps onto
        /// <xsl:value-of select="concat( ' _', $keyfield)"/>
        /// &lt;/summary&gt;
        [Obsolete]
        public override int Key
        {
          get { return <xsl:value-of select="concat( ' _', $keyfield)"/>; }
        }
        
          </xsl:otherwise>
        </xsl:choose>
        /// &lt;summary&gt;
        /// Auto-generated overridden property for the Key slot, maps onto
        /// &lt;/summary&gt;
        public override string KeyString {
          get {
          <xsl:choose>
          <xsl:when test="@natural-key">
            <xsl:variable name="key" select="@natural-key"/>
            <xsl:choose>
              <xsl:when test="adl:property[@name=$key]/@type = 'entity'">
                <xsl:value-of select="concat( 'return ', adl:property[@name=$key]/@entity, '.KeyString;')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat( 'return ', $key, '.ToString();')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="adl:key">
              StringBuilder result = new StringBuilder();
            <xsl:for-each select="adl:key/adl:property">
              result.Append(<xsl:value-of select="@name"/><xsl:if test="@type='entity'">.KeyString</xsl:if>);
              <xsl:if test="position()!=last()">
              result.Append('|');
              </xsl:if>
            </xsl:for-each>
              return result.ToString();
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="concat( 'return ', @name, 'Id.ToString();')"/>
          </xsl:otherwise>
        </xsl:choose> 
          }
        }
        
        /// &lt;summary&gt;
        /// A user readable distinct identifying string
        /// &lt;/summary&gt;        
        public override string UserIdentifier
        {
          get {
            StringBuilder result = new StringBuilder();
          <xsl:choose>
            <xsl:when test="adl:property[@distinct='user']">
              <xsl:for-each select="adl:property[@distinct='user']">
                <xsl:choose>
                  <xsl:when test="@type='message'">
            if ( <xsl:value-of select="@name"/> != null)
              result.Append( <xsl:value-of select="concat( @name, '.LocalText')"/>);
                  </xsl:when>
                  <xsl:when test="@type='entity'">
                    <!-- TODO: this is dangerous and could potentially give rise to 
                      infinite loops; find a way of stopping it running away! -->
            if ( <xsl:value-of select="@name"/> != null)
              result.Append( <xsl:value-of select="concat( @name, '.UserIdentifier')"/>);
                  </xsl:when>
                  <xsl:when test="@type='date'">
                    <!-- if what we've got is just a date, we only want to see the date part of it -->
            if ( <xsl:value-of select="@name"/> != null)
              result.Append(<xsl:value-of select="@name"/>.ToString( "d"));
                  </xsl:when>
                  <xsl:when test="@type='time'">
                    <!-- if what we've got is just a time, we only want to see the time part of it -->
            if ( <xsl:value-of select="@name"/> != null)
              result.Append(<xsl:value-of select="@name"/>.ToString( "t"));
                  </xsl:when>
                  <xsl:otherwise>
            if ( <xsl:value-of select="@name"/> != null)
              result.Append(<xsl:value-of select="@name"/>);
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
              <xsl:when test="position() = last()"/>
              <xsl:otherwise>
            result.Append( ", ");
              </xsl:otherwise>
            </xsl:choose>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
            result.AppendFormat( "<xsl:value-of select="@name"/>#{0}", KeyString);
            </xsl:otherwise>
          </xsl:choose>
          
            return result.ToString();
          }
        }
    
        /// &lt;summary&gt;
        /// If I should not be deleted, return a message explaining why I should not be deleted; else null.
        /// &lt;/summary&gt;
        /// &lt;returns&gt;a message explaining why I should not be deleted; else null&lt;/returns&gt;
        public override string NoDeleteReason {
          get {
            string result = null;
          <xsl:if test="adl:property[@type='list']|adl:property[@type='link']">
            StringBuilder bob = new StringBuilder();
            <!-- TODO: we ought to start worrying about internationalisation NOW, not later! -->
          
            <xsl:for-each select="adl:property[@type='list']|adl:property[@type='link']">
              <xsl:choose>
                <xsl:when test="@cascade='manual'"/>
                <xsl:when test="@cascade='all'"/>
                <xsl:when test="@cascade='all-delete-orphan'"/>
                <xsl:when test="@cascade='delete'"/>
                <xsl:otherwise>
            if ( <xsl:value-of select="concat( ' _', @name)"/> != null &amp;&amp; <xsl:value-of select="concat( ' _', @name)"/>.Count > 0) {
                bob.AppendFormat("Cannot delete this <xsl:value-of select="../@name"/> as it has {0} dependent <xsl:value-of select="@name"/>; ", <xsl:value-of select="concat( ' _', @name)"/>.Count);
            }

                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            if (bob.Length > 0) {
                result = bob.ToString();
            }
          </xsl:if>
            return result;
          }
        }
    <!-- 'descendant' to catch properties inside keys as well as properties which are direct children -->
    <xsl:apply-templates select="descendant::adl:property"/>
      }
    }


  </xsl:template>

  <xsl:template match="adl:property[@concrete='false']">
    <!-- generate nothing for non-concrete properties -->
        /* NOTE: property '<xsl:value-of select="@name"/>' is marked as being abstract; it must
         * be supported by manually maintained code */
  </xsl:template>
  
  <xsl:template match="adl:property">
        // auto generating iv/property pair for slot with name <xsl:value-of select="@name"/>
    <xsl:apply-templates select="help"/>

    <xsl:variable name="base-type">
      <xsl:call-template name="base-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="csharp-type">
      <xsl:call-template name="csharp-type">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="nullable-decoration">
      <xsl:choose>
        <xsl:when test="@required='true'"/>
        <!-- when required is 'true' null is not permitted anyway; otherwise... -->
        <xsl:when test="@type='message'"/>
        <xsl:when test="$base-type='entity'"/>
        <xsl:when test="$base-type='string'"/>
        <xsl:when test="$base-type='text'"/>
        <!-- entities and strings are always nullable, don't need decoration -->
        <xsl:when test="$base-type='list'"/>
        <xsl:when test="$base-type='link'"/>
        <!-- things which are collections are not nullable -->
        <xsl:otherwise>?</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="initialiser">
      <xsl:choose>
        <xsl:when test="@default">
          <xsl:choose>
            <xsl:when test="$csharp-type = 'String'">
              = "<xsl:value-of select="@default"/>"
            </xsl:when>
            <xsl:otherwise>
              = <xsl:value-of select="@default"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="normalize-space( $nullable-decoration) = '?'"> = null</xsl:when>
        <xsl:when test="$base-type = 'Boolean'"> = false</xsl:when>
        <xsl:when test="$base-type = 'int'"> = 0</xsl:when>
        <xsl:when test="$csharp-type = 'Decimal'"> = 0.0M</xsl:when>
        <xsl:when test="$base-type = 'real'"> = 0.0</xsl:when>
        <xsl:when test="$base-type='String'"> = null</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="validationpattern">
      <xsl:choose>
        <xsl:when test="@type='defined'">
          <xsl:variable name="definition">
            <xsl:value-of select="@typedef"/>
          </xsl:variable>
          <xsl:value-of select="//adl:typedef[@name=$definition]/@pattern"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string-length( $validationpattern) &gt; 0">
        private Regex <xsl:value-of select="@name"/>Validator = new Regex( "<xsl:value-of select="$validationpattern"/>");
    </xsl:if>

        private <xsl:value-of select="normalize-space( $csharp-type)"/><xsl:value-of select="normalize-space( $nullable-decoration)"/> <xsl:value-of select="concat( ' _', @name)"/> <xsl:value-of select="normalize-space( $initialiser)"/>;

        /// &lt;summary&gt;
        /// <xsl:choose>
          <xsl:when test="adl:documentation">
            <xsl:value-of select="normalize-space( adl:documentation)"/>
          </xsl:when>
          <xsl:otherwise>Auto generated property for field <xsl:value-of select="@name"/></xsl:otherwise>
        </xsl:choose><xsl:if test="help[@locale=$locale]">:
        /// <xsl:value-of select="normalize-space( help[@locale=$locale])"/></xsl:if>
        /// &lt;/summary&gt;
        public virtual <xsl:value-of select="normalize-space( $csharp-type)"/><xsl:value-of select="normalize-space( $nullable-decoration)"/><xsl:text> </xsl:text> <xsl:value-of select="@name"/>
        {
          get { 
            <xsl:if test="$base-type='list'">
            if ( <xsl:value-of select="concat( ' _', @name)"/> == null) {
              <xsl:value-of select="concat( '_', @name)"/> = new HashedSet&lt;<xsl:value-of select="@entity"/>&gt;();
            }
            </xsl:if>
            
            return <xsl:value-of select="concat( ' _', @name)"/>;
          }
          set {
              <xsl:if test="@required='true'">
            if ( value == null)
            {
              throw new DataRequiredException( <xsl:choose>
                <xsl:when test="ifmissing[@locale=$locale]">
                  <xsl:apply-templates select="ifmissing"/>
                </xsl:when>
                <xsl:otherwise>
                  "The value for <xsl:value-of select="@name"/> may not be set to null"
                </xsl:otherwise>
              </xsl:choose>
                );
            }
          </xsl:if>
  <xsl:if test="@type='defined'">
    <xsl:variable name="definition">
      <xsl:value-of select="@typedef"/>
    </xsl:variable>
    <xsl:variable name="maximum">
      <xsl:value-of select="//adl:typedef[@name=$definition]/@maximum"/>
    </xsl:variable>
    <xsl:variable name="minimum">
      <xsl:value-of select="//adl:typedef[@name=$definition]/@minimum"/>
    </xsl:variable>
    <xsl:if test="string-length( $maximum) &gt; 0">
            if ( value &gt; <xsl:value-of select="$maximum"/>)
            {
              throw new DataRangeException( "The maximum permitted value for <xsl:value-of select="@name"/> is <xsl:value-of select="$maximum"/>");
            }
    </xsl:if>
    <xsl:if test="string-length( $minimum) &gt; 0">
            if ( value &lt; <xsl:value-of select="$minimum"/>)
            {
              throw new DataRangeException( "The minimum permitted value for <xsl:value-of select="@name"/> is <xsl:value-of select="$minimum"/>");
            }
    </xsl:if>
    <xsl:if  test="string-length( $validationpattern) &gt; 0">
            if ( value != null &amp;&amp; ! <xsl:value-of select="@name"/>Validator.IsMatch( value))
            {
              throw new DataFormatException( string.Format( "The value supplied ({0}) does not match the format required by <xsl:value-of select="@name"/>", value));
            }
    </xsl:if>
  </xsl:if>
    <xsl:if test="@size and $csharp-type='String'">
            if ( value != null &amp;&amp; value.Length > <xsl:value-of select="@size"/>)
            {
              value = value.Substring( 0, <xsl:value-of select="@size"/>);
            }
    </xsl:if>
            <xsl:value-of select="concat( ' _', @name)"/> = value;
          }
        }

    <xsl:if test="parent::adl:key and @type='entity'">
        /* generate primitive value getter/setter for key property of type entity (experimental) */
      <xsl:variable name="csharp-base-type">
        <xsl:call-template name="csharp-base-type">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>
      </xsl:variable>
        private <xsl:value-of select="concat( $csharp-base-type, ' _', @name, '_Value')"/> <xsl:choose>
        <xsl:when test="$csharp-base-type = 'Boolean'"> = false</xsl:when>
        <xsl:when test="$csharp-base-type = 'int'"> = 0</xsl:when>
        <xsl:when test="$csharp-base-type = 'Decimal'"> = 0.0M</xsl:when>
        <xsl:when test="$csharp-base-type = 'real'"> = 0.0</xsl:when>
        <xsl:when test="$csharp-base-type='String'"> = null</xsl:when>
          <xsl:otherwise>[unknown? <xsl:value-of select="$csharp-base-type"/>]
        </xsl:otherwise>
      </xsl:choose>;

        public virtual <xsl:value-of select="concat( $csharp-base-type, ' ', @name, '_Value')"/> {
          get { return <xsl:value-of select="concat( '_', @name, '_Value')"/>; }
          set { <xsl:value-of select="concat( '_', @name, '_Value')"/> = value; }
        }
    </xsl:if>

  </xsl:template>

  <xsl:template match="adl:help">
    <xsl:if test="@locale=$locale">
    <!-- might conceivably be more than one line -->
      <xsl:text>
        /* </xsl:text><xsl:apply-templates/> */
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="ifmissing">
    <xsl:if test="@locale=$locale">
                  "<xsl:value-of select="normalize-space(.)"/>"
    </xsl:if>
  </xsl:template>

  <xsl:template name="initialise-lists">
    <!-- initialise all cocrete lists and links -->
    <xsl:for-each select="property[@type='list']">
      <xsl:choose>
        <xsl:when test="@concrete='false'"/>
        <xsl:otherwise>
      <xsl:value-of select="concat( ' _', @name)"/> = new HashedSet&lt;<xsl:value-of select="@entity"/>&gt;();
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:for-each select="property[@type='link']">
      <xsl:choose>
        <xsl:when test="@concrete='false'"/>
        <xsl:otherwise>
      <xsl:value-of select="concat( ' _', @name)"/> = new HashedSet&lt;<xsl:value-of select="@entity"/>&gt;();
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>