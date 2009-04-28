<?xml version="1.0" encoding="UTF-8" ?>
<!--
    Application Description Language framework
    adl2entityclass.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into C# entity classes
    
    $Author: sb $
    $Revision: 1.20 $
    $Date: 2009-04-28 13:44:51 $
  -->

<!-- WARNING WARNING WARNING: Do NOT reformat this file! 
     Whitespace (or lack of it) is significant! -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:adl="http://libs.cygnets.co.uk/adl/1.3/"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt">

	<xsl:include href="csharp-type-include.xslt"/>

	<xsl:output encoding="UTF-8" method="text"/>

	<!-- The locale for which these entities are generated 
      TODO: Entities should NOT be locale specific. Instead, the
      entity should generate messages based on the 
      client's locale. However, there may still need to be a concept of a
      'default locale', for when we don't have messages which suit the
      client's locale -->
	<xsl:param name="locale" select="en-GB"/>

	<!-- The C# namespace within which I shall generate controllers -->
	<xsl:param name="controllerns" select="Unset"/>

	<!-- The C# namespace within which I shall generate entities -->
	<xsl:param name="entityns" select="Unset"/>

	<!-- the name and version of the product being built -->
	<xsl:param name="product-version" select="'Application Description Language Framework'"/>

	<!-- Whether to authenticate at application or at database layer. 
    If not 'Application', then 'Database'. -->
	<xsl:param name="authentication-layer" select="'Application'"/>

	<!-- strings used in normalising names for constants. 
	NOTE NOTE NOTE: 
	this deliberately converts space and punctuation to underscore -->
	<xsl:variable name="notpermittedinconstantname">abcdefghijklmnopqrstuvwxyz .,;:?/()</xsl:variable>
	<xsl:variable    name="permittedinconstantname">ABCDEFGHIJKLMNOPQRSTUVWXYZ_________</xsl:variable>

	<xsl:template match="adl:application">
		<xsl:apply-templates select="adl:group"/>
		<xsl:apply-templates select="adl:entity"/>
	</xsl:template>

	<!-- Don't bother generating anything for foreign entities -->
	<xsl:template match="adl:entity[@foreign='true']"/>

	<xsl:template match="adl:group">
		/* ---- [ cut here: next file '<xsl:value-of select="concat( 'AuthCheck', @name)"/>.auto.cs'] ---------------- */

		//-------------------------------------------------------------
		//
		//  <xsl:value-of select="$product-version"/>
		//  <xsl:value-of select="concat( 'AuthCheck', @name)"/>.auto.cs
		//
		//  (c)2007 Cygnet Solutions Ltd
		//
		//  Automatically generated from application description using
		//  adl2entityclass.xsl revision <xsl:value-of select="substring( '$Revision: 1.20 $', 10)"/>
		//
		//  <xsl:value-of select="/adl:application/@revision"/>
		//
		//  This file is automatically generated; DO NOT EDIT IT.
		//
		//-------------------------------------------------------------
		using System;
		using System.Configuration;
		using System.Collections;
		using System.Collections.Generic;
		using System.Text;
		using System.Text.RegularExpressions;
		using Cygnet.Exceptions;
		using Cygnet.Entities;
		using Iesi.Collections.Generic;
		using NHibernate;
		using NHibernate.Classic;

		namespace <xsl:value-of select="$entityns"/>
		{
		/// &lt;summary&gt;
		/// Dummy entity class for security group <xsl:value-of select="@name"/>
		/// <xsl:value-of select="normalize-space( adl:documentation)"/>
		/// &lt;/summary&gt;
		/// &lt;remarks&gt;
		/// Automatically generated from description of group <xsl:value-of select="@name"/>
		/// using adl2entityclass.xsl revision <xsl:value-of select="substring( '$Revision: 1.20 $', 10)"/>.
		///
		/// DO NOT EDIT THIS FILE!
		/// &lt;/remarks&gt;
		public class <xsl:value-of select="concat( 'AuthCheck', @name)"/> : Entity {
			private int _Check;
			public virtual int Check {
				get { return Check; }
				set { _Check = value; }
			}
		}
		}
	</xsl:template>
	
	<xsl:template match="adl:entity">

		/* ---- [ cut here: next file '<xsl:value-of select="@name"/>.auto.cs'] ---------------- */

		//-------------------------------------------------------------
		//
		//  <xsl:value-of select="$product-version"/>
		//  <xsl:value-of select="@name"/>.auto.cs
		//
		//  (c)2007 Cygnet Solutions Ltd
		//
		//  Automatically generated from application description using
		//  adl2entityclass.xsl revision <xsl:value-of select="substring( '$Revision: 1.20 $', 10)"/>
		//
		//  <xsl:value-of select="/adl:application/@revision"/>
		//
		//  This file is automatically generated; DO NOT EDIT IT.
		//
		//-------------------------------------------------------------
		using System;
		using System.Configuration;
		using System.Collections;
		using System.Collections.Generic;
		using System.Text;
		using System.Text.RegularExpressions;
		using Cygnet.Exceptions;
		using Cygnet.Entities;
		using Iesi.Collections.Generic;
		using NHibernate;
		using NHibernate.Classic;

		namespace <xsl:value-of select="$entityns"/>
		{
		/// &lt;summary&gt;
		/// <xsl:value-of select="normalize-space( adl:documentation)"/>
		/// &lt;/summary&gt;
		/// &lt;remarks&gt;
		/// Automatically generated from description of entity <xsl:value-of select="@name"/>
		/// using adl2entityclass.xsl revision <xsl:value-of select="substring( '$Revision: 1.20 $', 10)"/>.
		/// Note that manually maintained parts of this class may be defined in
		/// a separate file called <xsl:value-of select="@name"/>.manual.cs, q.v.
		///
		/// DO NOT EDIT THIS FILE!
		/// &lt;/remarks&gt;
		public partial class <xsl:value-of select="@name"/> : Entity
		{
		#if DEBUG
		/// &lt;summary&gt;
		/// while debugging, keep track of the number of live instances
		/// &lt;/summary&gt;
		public volatile static int instances = 0;
		#endif
		/// &lt;summary&gt;
		/// Auto-generated no-args constructor; does nothing (but probably should
		/// ensure ID slot is initialised correctly)
		/// &lt;/summary&gt;
		public <xsl:value-of select="@name"/>() : base(){
		<xsl:call-template name="initialise-lists"/>
		
		#if DEBUG
		/* while debugging, keep track of the number of live instances; increment on creation */
		instances ++;
		#endif
		}

		#if DEBUG
		/// &lt;summary&gt;
		/// while debugging, keep track of the number of live instances; decrement on deletion
		/// &lt;/summary&gt;
		<xsl:value-of select="concat( '~', @name)"/>() {
		instances --;
		}
		#endif
 
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
				<xsl:call-template name="initialise-messages"/>

				<xsl:for-each select="adl:key/adl:property">
					this.<xsl:value-of select="@name"/> = <xsl:value-of select="@name"/>;
				</xsl:for-each>
				}

			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate="yes">
					ADL: ERROR: Entity '<xsl:value-of select="@name"/>' has no key. Was the
					canonicalise stage missed in the build process?
				</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
		/// &lt;summary&gt;
		/// Auto-generated overridden property for the Key slot, maps onto
		/// &lt;/summary&gt;
		public override string KeyString {
		get {
		StringBuilder result = new StringBuilder();
		<xsl:for-each select="adl:key/adl:property">
			result.Append(<xsl:value-of select="@name"/><xsl:if test="@type='entity'">.KeyString</xsl:if>);
			<xsl:if test="position()!=last()">
				result.Append('|');
			</xsl:if>
		</xsl:for-each>
		return result.ToString();
		}
		}

		/// &lt;summary&gt;
		/// True if I have not yet been persisted to the database, else false.
		/// NOTE: This code is experimental and may change!
		/// &lt;/summary&gt;
		public override Boolean IsNew {
		get {
		Boolean result = false;
		<xsl:for-each select="descendant::adl:property[adl:generator]">
			<xsl:choose>
				<xsl:when test="@type='integer'">
					if ( <xsl:value-of select="@name"/> == 0) {
					result = true;
					}
				</xsl:when>
				<xsl:when test="@type='string'">
					if ( String.IsNullOrEmpty( <xsl:value-of select="@name"/>)) {
					result = true;
					}
				</xsl:when>
				<xsl:otherwise>
					/* TODO: ADL does not yet correctly generate IsNew for
					* properties of type <xsl:value-of select="@type"/> */
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		return result;
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
			<xsl:when test="descendant::adl:property[@distinct='user' or @distinct='all']">
				<xsl:for-each select="descendant::adl:property[@distinct='user' or @distinct='all']">
					<xsl:choose>
						<xsl:when test="@type='message'">
							if ( <xsl:value-of select="@name"/> != null){
							result.Append( <xsl:value-of select="concat( @name, '.LocalText')"/>);
							}
						</xsl:when>
						<xsl:when test="@type='entity'">
							<!-- TODO: this is dangerous and could potentially give rise to 
                      infinite loops; find a way of stopping it running away! -->
							if ( <xsl:value-of select="@name"/> != null){
							result.Append( <xsl:value-of select="concat( @name, '.UserIdentifier')"/>);
							}
						</xsl:when>
						<xsl:when test="@type='date'">
							<!-- if what we've got is just a date, we only want to see the date part of it -->
							if ( <xsl:value-of select="@name"/> != null){
							result.Append(((DateTime)<xsl:value-of select="@name"/>).ToShortDateString());
							}
						</xsl:when>
						<xsl:when test="@type='time'">
							<!-- if what we've got is just a time, we only want to see the time part of it -->
							if ( <xsl:value-of select="@name"/> != null){
							result.Append(((DateTime)<xsl:value-of select="@name"/>).ToShortTimeString());
							}
						</xsl:when>
						<xsl:when test="@required = 'true' and (@type = 'integer' or @type = 'real' or @type = 'boolean' or @type = 'money')">
							<!-- can't be null because we will have generated a non-nullable type -->
							result.Append(<xsl:value-of select="@name"/>.ToString());
						</xsl:when>
						<xsl:otherwise>
							if ( <xsl:value-of select="@name"/> != null){
							result.Append(<xsl:value-of select="@name"/>);
							}
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="position() = last()"/>
						<xsl:otherwise>
							result.Append( ",");
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
							<xsl:when test="@concrete='false'"/>
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

		/// &lt;summary&gt;
		/// Should I permit myself to be deleted? If I have a valid NoDeleteReason then no. Otherwise
		/// I should remove my backlinks to entities which list me in lists which have 'inverse="true"'
		/// &lt;/summary&gt;
		/// &lt;returns&gt;a veto if I should not be deleted; else no veto&lt;/returns&gt;
		public override LifecycleVeto OnDelete(ISession hibernator) {
		string ndr = NoDeleteReason;
		LifecycleVeto result = LifecycleVeto.NoVeto;
		if ( ndr != null) {
		result = LifecycleVeto.Veto;
		} else {
		_indeletion = true;
		<xsl:for-each select="adl:property[ @type='entity']">
			<!-- if the property is not a magic backlink, nulling it before deleting does no harm.
				if it is a magic backlink, nulling it will(?) clear the reference at the far end. -->
			<xsl:value-of select="@name"/> = null;
		</xsl:for-each>
		}
		return result;
		}

		<!-- 'descendant' to catch properties inside keys as well as properties which are direct children -->
		<xsl:apply-templates select="descendant::adl:property"/>
		}
    
    /// A prototype for <xsl:value-of select="@name"/> used when initialising forms for which
    /// there is as yet no real record. This has only those properties of <xsl:value-of select="@name"/>
    /// which have default values. Objects of this class are not known to NHibernate and are
    /// never persisted to the database.
    public class <xsl:value-of select="concat( 'PrototypeFor', @name)"/> {

    /// Dummy IsNew property always returns true
    public Boolean IsNew { get { return true; }}

    /// Dummy user identifier which always returns just '[new]'
    public string UserIdentifier { get { return "[new]";}}

    <xsl:for-each select="adl:property">
      <xsl:call-template name="prototype-property">
        <xsl:with-param name="property" select="."/>
      </xsl:call-template>
    </xsl:for-each>
    }
    }
    /* ---- [ cut here: next file 'junk'] ------------------------- */

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
				<xsl:when test="$base-type = 'integer'"> = 0</xsl:when>
				<xsl:when test="$csharp-type = 'Decimal'"> = 0.0M</xsl:when>
				<xsl:when test="$base-type = 'real'"> = 0.0</xsl:when>
				<xsl:when test="$csharp-type = 'String'">
					<xsl:choose>
						<xsl:when test="@required='true'">
							= ""
						</xsl:when>
						<xsl:otherwise>
							= null
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
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

		<xsl:if test="$base-type = 'integer'">
			<xsl:for-each select="adl:option">
				<xsl:variable name="constname">
					<xsl:call-template name="constname">
						<xsl:with-param name="option" select="."/>
						<xsl:with-param name="locale" select="$locale"/>
					</xsl:call-template>
				</xsl:variable>
				public const int <xsl:value-of select="$constname"/> = 
				<xsl:choose>
					<xsl:when test="@value">
						<xsl:value-of select="@value"/>
					</xsl:when>
					<xsl:when test="adl:prompt[@locale='default']/@prompt">
						<xsl:value-of select="adl:prompt[@locale='default']/@prompt"/>
					</xsl:when>
					<xsl:when test="adl:prompt[@locale=$locale]/@prompt">
						<xsl:value-of select="adl:prompt[@locale=$locale]/@prompt"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message terminate="yes">
							ADL: ERROR: Cannot infer a value for option
						</xsl:message>
					</xsl:otherwise>
				</xsl:choose>;
			</xsl:for-each>
		</xsl:if>

		private <xsl:value-of select="normalize-space( $csharp-type)"/><xsl:value-of select="normalize-space( $nullable-decoration)"/> <xsl:value-of select="concat( ' _', @name)"/> <xsl:value-of select="normalize-space( $initialiser)"/>;

		/// &lt;summary&gt;
		<xsl:choose>
			<xsl:when test="adl:documentation">
				/// <xsl:value-of select="normalize-space( adl:documentation)"/>
			</xsl:when>
			<xsl:otherwise>
				/// Auto generated property for field <xsl:value-of select="@name"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="help[@locale=$locale]">
			/// <xsl:value-of select="normalize-space( help[@locale=$locale])"/>
		</xsl:if>
		/// &lt;/summary&gt;
		<xsl:apply-templates select="adl:prompt"/>
		<!-- TODO: this should get the size right if type = 'defined', but hasn't been tested -->
		<xsl:if test="$base-type = 'string'">
			<xsl:variable name="base-size">
				<xsl:call-template name="base-size">
					<xsl:with-param name="property" select="."/>
				</xsl:call-template>
			</xsl:variable>
			[FieldWidth(<xsl:value-of select="$base-size"/>)]
		</xsl:if>
		<xsl:if test="@distinct = 'user' or @distinct = 'all'">[IsUserDistinct()]</xsl:if>
		<xsl:if test="@type = 'money'">[Dimension( "money",Unit="<xsl:value-of select="ancestor::adl:application/@currency"/>")]</xsl:if>
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
			<!-- If we could generate a non-nullable type we have done so; otherwise,
				must catch null -->
			<xsl:choose>
				<xsl:when test="@type='integer'"/>
				<xsl:when test="@type='real'"/>
				<xsl:when test="@type='money'">
					<!-- not quite certain of that - check! -->
				</xsl:when>
				<xsl:when test="@type='boolean'"/>
				<xsl:otherwise>
					if ( ! _indeletion &amp;&amp; value == null)
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
				</xsl:otherwise>
			</xsl:choose>
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
		<xsl:if test="adl:option">
			<xsl:choose>
				<xsl:when test="$base-type = 'integer'">
					<xsl:choose>
						<xsl:when test="@required='true'"/>
						<xsl:otherwise>
							if ( value != null){
						</xsl:otherwise>
					</xsl:choose>
						switch ( value ) {
							<xsl:for-each select="adl:option">
						case <xsl:call-template name="constname">
							<xsl:with-param name="option" select="."/>
							<xsl:with-param name="locale" select="$locale"/>
						</xsl:call-template>:
					</xsl:for-each>
					break;
					default:
					throw new DataRangeException( string.Format( "The value supplied ({0}) is not an acceptable value for <xsl:value-of select="@name"/>", value));
					}
					<xsl:choose>
						<xsl:when test="@required='true'"/>
						<xsl:otherwise>
							} <!-- matches brace on 'if ( value != null) {' above -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$base-type = 'string'">
					bool acceptable = false;
					
					<xsl:choose>
						<xsl:when test="@required='true'"/>
						<xsl:otherwise>
							if ( value == null) { acceptable = true; } else
						</xsl:otherwise>
					</xsl:choose>
					<xsl:for-each select="adl:option">
						if ( "<xsl:value-of select="@value"/>".Equals( value)) { acceptable = true; }
						<xsl:if test="position() != last()">else</xsl:if>
					</xsl:for-each>
					if ( ! acceptable) {
					throw new DataRangeException( string.Format( "The value supplied ('{0}') is not an acceptable value for <xsl:value-of select="@name"/>", value));
					}
				</xsl:when>
			</xsl:choose>
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
			/// &lt;summary&gt;
			/// auto generated primitive value for key property of type entity (experimental)
			/// &lt;/summary&gt;
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
				<xsl:otherwise>
					[unknown? <xsl:value-of select="$csharp-base-type"/>]
				</xsl:otherwise>
			</xsl:choose>;

			/// &lt;summary&gt;
			/// auto generated primitive value getter/setter for key property of type entity (experimental)
			/// &lt;/summary&gt;
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

	<xsl:template match="adl:prompt">
		[LocalisedDisplayName( "<xsl:value-of select="@prompt"/>", Locale="<xsl:value-of select="@locale"/>")]
	</xsl:template>

	<xsl:template match="ifmissing">
		<xsl:if test="@locale=$locale">
			"<xsl:value-of select="normalize-space(.)"/>"
		</xsl:if>
	</xsl:template>

	<xsl:template name="initialise-messages">
		<!-- each IV of type message needs to be initialised -->
		<xsl:for-each select="adl:property[@type='message']">
			<xsl:choose>
				<xsl:when test="@concrete='false'"/>
				<xsl:otherwise>
					<xsl:value-of select="concat( ' _', @name)"/> = new Message();
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="initialise-lists">
		<!-- initialise all concrete lists and links -->
		<xsl:for-each select="adl:property[@type='list' or @type='link']">
			<xsl:choose>
				<xsl:when test="@concrete='false'"/>
				<xsl:otherwise>
					<xsl:value-of select="concat( ' _', @name)"/> = new HashedSet&lt;<xsl:value-of select="@entity"/>&gt;();
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<!-- produce a name for a constant value from an option entity -->
	<xsl:template name="constname">
		<xsl:param name="option"/>
		<xsl:param name="locale"/>
		<xsl:variable name="unnormalisedname">
		<xsl:choose>
			<xsl:when test="$option/adl:prompt[@locale='default']">
				<xsl:value-of select="concat( $option/ancestor::adl:property/@name, '_', 
							  $option/adl:prompt[@locale='default']/@prompt, '_value')"/>
			</xsl:when>
			<xsl:when test="$option/adl:prompt[@locale=$locale]">
				<xsl:value-of select="concat( $option/ancestor::adl:property/@name, '_', 
							  $option/adl:prompt[@locale=$locale]/@prompt, '_value')"/>
			</xsl:when>
			<xsl:when test="$option/@value">
				<xsl:value-of select="concat( $option/ancestor::adl:property/@name, '_', 
							  $option/@value, '_value')"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- this one's dodgy but shouldn't be hit often (perhaps never) -->
				<xsl:value-of select="concat( $option/ancestor::adl:property/@name, '_',
							  position(), '_value')"/></xsl:otherwise>
		</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="translate($unnormalisedname, 
					  $notpermittedinconstantname, $permittedinconstantname)"/>
	</xsl:template>

  <xsl:template name="prototype-property">
    <xsl:param name="property"/>
      <xsl:apply-templates select="help"/>

      <xsl:variable name="base-type">
        <xsl:call-template name="base-type">
          <xsl:with-param name="property" select="$property"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="csharp-type">
        <xsl:call-template name="csharp-type">
          <xsl:with-param name="property" select="$property"/>
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
              "<xsl:value-of select="@default"/>"
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@default"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$nullable-decoration = '?'">
          null
        </xsl:when>
        <xsl:when test="$base-type = 'Boolean'">false</xsl:when>
        <xsl:when test="$base-type = 'integer'">0</xsl:when>
        <xsl:when test="$csharp-type = 'Decimal'">0.0M</xsl:when>
        <xsl:when test="$base-type = 'real'">0.0</xsl:when>
        <xsl:when test="$base-type = 'date'">new DateTime()</xsl:when>
        <xsl:when test="$csharp-type = 'String'">
          <xsl:choose>
            <xsl:when test="@required='true'">
              ""
            </xsl:when>
            <xsl:otherwise>
              null
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          null
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    /// &lt;summary&gt;
    /// Auto generated prototype property for field <xsl:value-of select="$property/@name"/>
    /// &lt;/summary&gt;
    <xsl:apply-templates select="adl:prompt"/>
    <!-- TODO: this should get the size right if type = 'defined', but hasn't been tested -->
    <xsl:if test="$base-type = 'string'">
      <xsl:variable name="base-size">
        <xsl:call-template name="base-size">
          <xsl:with-param name="property" select="$property"/>
        </xsl:call-template>
      </xsl:variable>
      [FieldWidth(<xsl:value-of select="$base-size"/>)]
    </xsl:if>
    <xsl:if test="$property/@distinct = 'user' or $property/@distinct = 'all'">[IsUserDistinct()]</xsl:if>
    <xsl:if test="$property/@type = 'money'">
      [Dimension( "money",Unit="<xsl:value-of select="$property/ancestor::adl:application/@currency"/>")]
    </xsl:if>
    public virtual <xsl:value-of select="normalize-space( $csharp-type)"/><xsl:value-of select="$nullable-decoration"/><xsl:text> </xsl:text> <xsl:value-of select="@name"/>
    {
    get { return <xsl:value-of select="normalize-space( $initialiser)"/>;}
    }
    
  </xsl:template>
</xsl:stylesheet>