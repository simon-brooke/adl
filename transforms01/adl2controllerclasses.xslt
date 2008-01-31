<?xml version="1.0" encoding="UTF-8"?>

  <!--
    C1873 SRU Hospitality
    adl2controllerclasses.xsl
    
    (c) 2007 Cygnet Solutions Ltd
    
    Transform ADL into (partial) controller classes
    
    $Author: sb $
    $Revision: 1.1 $
    $Date: 2008-01-31 17:06:35 $
  -->

  <!-- WARNING WARNING WARNING: Do NOT reformat this file! 
     Whitespace (or lack of it) is significant! -->
  <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="UTF-8" method="text"/>

    <!-- The locale for which these controllers are generated 
      TODO: Controllers should NOT be locale specific. Instead, the
      controller should render views and generate messages based on the 
      client's locale. However, there may still need to be a concept of a
      'default locale', for when we don't have messages which suit the
      client's locale -->
    <xsl:param name="locale" select="en-UK"/>

    <!-- The C# namespace within which I shall generate controllers -->
    <xsl:param name="controllerns" select="Unset"/>
    <!-- The C# namespace used by the entities for this project -->
    <xsl:param name="entityns" select="Unset"/>
    
    <xsl:template match="application">
      <xsl:apply-templates select="entity"/>
    </xsl:template>

    <xsl:template match="entity">
      <!-- what's all this about? the objective is to get the revision number of the 
    transform into the output, /without/ getting that revision number overwritten 
    with the revision number of the generated file if the generated file is 
    stored to CVS -->
      <xsl:variable name="transform-rev1"
                    select="substring( '$Revision: 1.1 $', 11)"/>
      <xsl:variable name="transform-revision"
                    select="substring( $transform-rev1, 0, string-length( $transform-rev1) - 1)"/>

      <xsl:variable name="key">
        <xsl:call-template name="primary-key">
          <xsl:with-param name="entityname" select="@name"/>
        </xsl:call-template>
      </xsl:variable>

/* ---- [ cut here: next file '<xsl:value-of select="@name"/>Controller.auto.cs'] ---------------- */

//------------------------------------------------------------------
//
//  Application Description Framework
//  <xsl:value-of select="@name"/>Controller.auto.cs
//
// (c) 2007 Cygnet Solutions Ltd
//
//  Controller for auto-generated forms for editing <xsl:value-of select="@name"/>s
//  Automatically generated from application description using
//  adl2controllerclass.xsl version <xsl:value-of select="$transform-revision"/>
//
//  This file is automatically generated; DO NOT EDIT IT.
//
//------------------------------------------------------------------

using System;
using System.Data;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using Castle.MonoRail.Framework.Helpers;
using Cygnet.Web.Helpers;
using Cygnet.Web.Controllers;
using NHibernate;
using NHibernate.Expression;
using Castle.MonoRail.Framework;
using Cygnet.Exceptions;
using Iesi.Collections.Generic;
using SRU.Hospitality.Helpers;
using SRU.Hospitality.Entities;

namespace <xsl:value-of select="$controllerns"/> {

  /// &lt;summary&gt;
  /// Automatically generated partial controller class following 'thin controller'
  /// strategy, for entity <xsl:value-of select="@name"/>. Note that part of this
  /// class may be defined in a separate file called 
  /// <xsl:value-of select="@name"/>Controller.manual.cs, q.v.
  ///
  /// DO NOT EDIT THIS FILE!
  /// &lt;/summary&gt;
  public partial class <xsl:value-of select="@name"/>Controller : BaseController {

      /// &lt;summary&gt;
      /// Store the record represented by the parameters passed in an HTTP service
      /// Without Id -&gt; it's new, I create a new persistent object;
      /// With Id -&gt; it's existing, I update the existing persistent object.
      /// NOTE: Should only be called from a handler for method 'POST', never 'GET'.
      /// &lt;/summary&gt;
      private void Store()
      {
        ISession hibernator = 
          NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
        List&lt;string&gt; messages = new List&lt;string&gt;();
      
        <xsl:value-of select="$entityns"/>.<xsl:value-of select="@name"/> record;
        
        <xsl:apply-templates select="property"/>

        string id = Form["<xsl:value-of select="concat( 'instance.', $key)"/>"];

        if ( String.IsNullOrEmpty( id))
        {
          /* it's new, create persistent object */
          record = new <xsl:value-of select="$entityns"/>.<xsl:value-of select="@name"/>(<xsl:for-each select="property[@distinct='system']">Form[<xsl:value-of select="concat( 'instance.', @name)"/>]<xsl:choose>
                <xsl:when test="position() = last()"/>
                <xsl:otherwise>, </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>);

          /* perform any domain knowledge behaviour on the new record 
           * after instantiation */
          record.AfterCreationHook( hibernator);
          messages.Add( "New <xsl:value-of select="@name"/> record created");
        }
        else
        {
          /* it's existing, retrieve it */
          record =
            hibernator.CreateCriteria(typeof(<xsl:value-of select="@name"/>))
              .Add(Expression.Eq("<xsl:value-of select="$key"/>", Int32.Parse(id)))
              .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@name"/>&gt;();
        }

        if ( record != null)
        {
          try
          {
            /* actually update the record */
            BindObjectInstance( record, ParamStore.Form, "instance");
            
      <xsl:for-each select="property[@type='entity']">
            /* for properties of type 'entity', it should not be necessary to do anything 
             * special - BindObjectInstance /should/ do it all. Unfortunately it sometimes 
             * doesn't, and I haven't yet characterised why not. TODO: Fix this! */
            record.<xsl:value-of select="@name"/> = 
              hibernator.CreateCriteria(typeof(<xsl:value-of select="@entity"/>))
                .Add(Expression.Eq("<xsl:call-template name="primary-key">
                  <xsl:with-param name="entityname" select="@entity"/>
                </xsl:call-template>", Int32.Parse(Form["<xsl:value-of select="concat( 'instance.', @name)"/>"])))
                .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@entity"/>&gt;();
      </xsl:for-each>
          
      <xsl:for-each select="property[@type='link']">  
            /* to update a link table which has no other data than the near and far keys, it is
             * sufficient to smash the existing values and create new ones. It's also a lot easier! */
        
            string[] <xsl:value-of select="concat(@name, 'Values')"/> = Form.GetValues( "<xsl:value-of select="concat( 'instance.', @name)"/>");
          
            if ( <xsl:value-of select="concat(@name, 'Values')"/> != null)
            {
              /* update the linking table for my <xsl:value-of select="@name"/>; first smash the old values */
              if ( <xsl:value-of select="concat( 'record.', @name)"/> != null)
              {
                <xsl:value-of select="concat( 'record.', @name)"/>.Clear();
              }
              else
              {
                <xsl:value-of select="concat( 'record.', @name)"/> = new HashedSet&lt;<xsl:value-of select="@entity"/>&gt;();
              }
            
              /* then reinstate the values from the indexes passed */
              foreach ( string index in <xsl:value-of select="concat(@name, 'Values')"/>)
              {
                <!-- todo: won't work for entities having natural keys -->
                <xsl:value-of select="concat( 'record.', @name)"/>.Add(
                  hibernator.CreateCriteria(typeof(<xsl:value-of select="@entity"/>))
                    .Add(Expression.Eq("<xsl:value-of select="@entity"/>Id", Int32.Parse(index)))
                    .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@entity"/>&gt;());
              }
            }
      </xsl:for-each>

      <xsl:for-each select="property[@type='list']">
            /* with a list we cannot just smash the old values! Instead we need to check 
             * each one and exclude it if no longer required */
            if ( Form.GetValues( "<xsl:value-of select="concat( 'instance.', @name)"/>") != null)
            {
              string[] <xsl:value-of select="concat(@name, 'Values')"/> = Form.GetValues( "<xsl:value-of select="concat( 'instance.', @name)"/>");

              /* updating <xsl:value-of select="@name"/> child records; first remove any not on the submitted list */
              foreach ( <xsl:value-of select="@entity"/> item in record.<xsl:value-of select="@name"/>)
              {
                String itemId = item.Key.ToString();
                bool found = false;

                foreach ( string index in <xsl:value-of select="concat(@name, 'Values')"/>)
                {
                  <!-- TODO: this could definitely be made more efficient -->
                  if ( index.Equals( itemId))
                  {
                    found = true;
                  }
                }
          
                if ( ! found)
                {
                  record.<xsl:value-of select="@name"/>.Remove( item);
                }
              }

              /* then add any on the included list which are not already members */
              foreach ( string index in <xsl:value-of select="concat(@name, 'Values')"/>)
              {
                <xsl:value-of select="@entity"/> item = 
                  hibernator.CreateCriteria(typeof(<xsl:value-of select="@entity"/>))
                    .Add(Expression.Eq("<xsl:value-of select="@entity"/>Id", Int32.Parse(index)))
                    .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@entity"/>&gt;();
              
                if ( ! record.<xsl:value-of select="@name"/>.Contains( item))
                {
                  record.<xsl:value-of select="@name"/>.Add( item);
                }
              }
            }
      </xsl:for-each>

            /* perform any domain knowledge behaviour on the record prior to updating */
            record.BeforeUpdateHook( hibernator);

            /* write the record to the database, in order to guarantee we have a valid key */
            hibernator.Save(record);
            hibernator.Flush();

            /* perform any domain knowledge behaviour on the record after updating */
            record.AfterUpdateHook( hibernator);
        
            messages.Add( "Record saved successfully");
          }
          catch ( DataSuitabilityException dse)
          {
            AddError( dse.Message);
          }
          catch ( ApplicationException axe)
          {
            AddError( axe.Message);
          }

          PropertyBag["messages"] = messages;
          PropertyBag["username"] = Session[ NHibernateHelper.USERTOKEN];
          PropertyBag["instance"] = record;

      <xsl:call-template name="menus">
        <xsl:with-param name="entity" select="."/>
      </xsl:call-template>
          RenderViewWithFailover("<xsl:value-of select="concat( form[position()=1]/@name, '.vm')"/>", "<xsl:value-of select="concat( form[position()=1]/@name, '.auto.vm')"/>");
        }
        else
        {
          throw new Exception( String.Format( "No record of type <xsl:value-of select="@name"/> with key value {0} found", id));
        }
      }

      /// &lt;summary&gt;
      /// Actually delete the selected record
      /// &lt;/summary&gt;
      [AccessibleThrough(Verb.Get)]
      public void Delete()
      {
        ISession hibernator = 
            NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
        string id = Params["<xsl:value-of select="concat( 'instance.', $key)"/>"];
        string reallydelete = Params["reallydelete"];
        
        if ( "true".Equals( reallydelete))
        { 
          <xsl:value-of select="@name"/> record =
            hibernator.CreateCriteria(typeof(<xsl:value-of select="@name"/>))
              .Add(Expression.Eq("<xsl:value-of select="$key"/>", Int32.Parse(id)))
              .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@name"/>&gt;();

          if ( record != null)
          {
            record.BeforeDeleteHook( hibernator);

            hibernator.Delete( 
              hibernator.CreateCriteria(typeof(<xsl:value-of select="@name"/>))
                .Add(Expression.Eq("<xsl:value-of select="$key"/>", Int32.Parse(id)))
                .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="@name"/>&gt;());

            hibernator.Flush();
          }
          else
          {
            throw new ApplicationException( "No such record?");
          }
        }
      <xsl:choose>
        <xsl:when test="list">
        InternalShowList();
        </xsl:when>
        <xsl:otherwise>
        Redirect( FormsAuthentication.DefaultUrl);
        </xsl:otherwise>
      </xsl:choose>
      }

      <xsl:apply-templates select="form"/>

      <xsl:if test="list">
        <xsl:variable name="listname" select="list[position()=1]/@name"/>
        <xsl:apply-templates select="list"/>
      /// &lt;summary&gt;
      /// list all instances of this entity to allow the user to select one for editing
      /// this method invokes the default list view - which is probably what you want unless
      /// you've a special reason for doing something different
      /// &lt;/summary&gt;
      public void InternalShowList()
      {
        InternalShowList( "<xsl:value-of select="$listname"/>");
      }

      /// &lt;summary&gt;
      /// list all instances of this entity to allow the user to select one for editing
      /// &lt;/summary&gt;
      /// &lt;param name="view"&gt;The name of the list view to show&lt;/param&gt;
      public void InternalShowList( String view)
      {
        ISession hibernator = 
          NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
        IList&lt;<xsl:value-of select="@name"/>&gt; instances = 
          hibernator.CreateCriteria(typeof(<xsl:value-of select="@name"/>))<xsl:for-each select="property[@distinct='user']">
            <xsl:value-of select="concat( '.AddOrder( new Order( &#34;', @name, '&#34;, true))')"/>
          </xsl:for-each>.List&lt;<xsl:value-of select="@name"/>&gt;();

        PropertyBag["username"] = Session[ NHibernateHelper.USERTOKEN];
        PropertyBag["instances"] =
        PaginationHelper.CreatePagination( this, instances, 25);

        RenderViewWithFailover(view + ".vm", view + ".auto.vm");
        }
      </xsl:if>
  }
}
    </xsl:template>

    <xsl:template match="property[@required='true']">
        if ( Form[ "<xsl:value-of select="concat( 'instance.', @name)"/>" ] == null)
        {
          AddError( <xsl:choose>
        <xsl:when test="ifmissing[@locale=$locale]">
          <xsl:apply-templates select="ifmissing[@locale=$locale]"/>
        </xsl:when>
        <xsl:otherwise>"You must supply a value for <xsl:value-of select="@name"/>"</xsl:otherwise>
      </xsl:choose>);
        }

    </xsl:template>

    <!-- suppress properties otherwise -->
    <xsl:template match="property"/>
        
    <xsl:template match="ifmissing">
      "<xsl:value-of select="normalize-space(.)"/>"
    </xsl:template>

    <xsl:template match="form">
      <xsl:variable name="key">
        <xsl:choose>
          <xsl:when test="../@natural-key">
            <xsl:value-of select="../@natural-key"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat( ../@name, 'Id')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      /// &lt;summary&gt;
      /// Handle the submission of the form named <xsl:value-of select="@name"/>
      /// &lt;/summary&gt;
      [AccessibleThrough(Verb.Post)]
      public void <xsl:value-of select="concat( @name, 'SubmitHandler')"/>( )
      {
        string command = Form[ "command"];
        
        if ( command == null)
        {
          throw new Exception( "No command?");
        }
        else
        <xsl:for-each select=".//verb">
        if ( command.Equals( "<xsl:value-of select="@verb"/>"))
        {
          /* NOTE: You must write an implementation of this verb in a
            manually maintained partial class file for this class */
          <xsl:value-of select="@verb"/>();
        }
        else
        </xsl:for-each>
        if ( command.Equals( "delete"))
        {
          ISession hibernator = 
            NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
          string id = Form["<xsl:value-of select="concat( 'instance.', $key)"/>"];

          PropertyBag["username"] = Session[ NHibernateHelper.USERTOKEN];
          PropertyBag["instance"] = 
            hibernator.CreateCriteria(typeof(<xsl:value-of select="../@name"/>))
              .Add(Expression.Eq("<xsl:value-of select="$key"/>", Int32.Parse(id)))
              .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="../@name"/>&gt;();
          
          RenderViewWithFailover( "maybedelete.vm", "maybedelete.auto.vm");
        }
        else if ( command.Equals( "store"))
        {
          Store();
        }
        else
        {
          throw new Exception( String.Format("Unrecognised command '{0}'", command));
        }
      }
            
      /// &lt;summary&gt;
      /// Show the form named <xsl:value-of select="@name"/>, with no content
      /// &lt;/summary&gt;
      [AccessibleThrough(Verb.Get)]
      public void <xsl:value-of select="@name"/>( )
      {
        ISession hibernator = 
          NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
      <xsl:call-template name="menus">
        <xsl:with-param name="entity" select=".."/>
      </xsl:call-template>

        PropertyBag["username"] = Session[ NHibernateHelper.USERTOKEN];
        RenderViewWithFailover("<xsl:value-of select="concat( @name, '.vm')"/>", "<xsl:value-of select="concat( @name, '.auto.vm')"/>");
      }

      /// &lt;summary&gt;
      /// Show the form named <xsl:value-of select="@name"/>, containing the indicated record 
      /// &lt;/summary&gt;
      /// &lt;param name="<xsl:value-of select="concat( ../@name, 'Id')"/>"&gt;the key value of the record to show&lt;/param&gt;
      [AccessibleThrough(Verb.Get)]
      public void <xsl:value-of select="@name"/>( Int32 <xsl:value-of select="concat( ../@name, 'Id')"/>)
      {
        ISession hibernator = 
          NHibernateHelper.GetCurrentSession( Session[ NHibernateHelper.USERTOKEN], 
                                              Session[NHibernateHelper.PASSTOKEN]);
        <xsl:value-of select="$entityns"/>.<xsl:value-of select="../@name"/> record =
          hibernator.CreateCriteria(typeof(<xsl:value-of select="../@name"/>))
            .Add(Expression.Eq("<xsl:value-of select="concat( ../@name, 'Id')"/>", <xsl:value-of select="../@name"/>Id))
            .UniqueResult&lt;<xsl:value-of select="$entityns"/>.<xsl:value-of select="../@name"/>&gt;();

        PropertyBag["username"] = Session[ NHibernateHelper.USERTOKEN];
        PropertyBag["instance"] = record;

      <xsl:call-template name="menus">
        <xsl:with-param name="entity" select=".."/>
      </xsl:call-template>
        RenderViewWithFailover("<xsl:value-of select="concat( @name, '.vm')"/>", "<xsl:value-of select="concat( @name, '.auto.vm')"/>");
      }

    </xsl:template>

    <xsl:template match="list">
      /// &lt;summary&gt;
      /// list all instances of this entity to allow the user to select one
      /// this method invokes the named view.
      /// &lt;/summary&gt;
      public void <xsl:value-of select="@name"/>()
      {
        InternalShowList( "<xsl:value-of select="@name"/>");
      }

    </xsl:template>

    <xsl:template name="menus">
      <xsl:param name="entity"/>
      <xsl:for-each select="$entity/property[@type='entity']">
          /* produce a list of <xsl:value-of select="@entity"/> to populate the menu for <xsl:value-of select="@name"/> */
        <xsl:call-template name="menu">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>

      </xsl:for-each>
      <xsl:for-each select="$entity/property[@type='link']">
          /* produce a list of <xsl:value-of select="@entity"/> to populate the LHS of the shuffle for <xsl:value-of select="@name"/> */
        <xsl:call-template name="menu">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:for-each select="$entity/property[@type='list']">
          /* produce a list of <xsl:value-of select="@entity"/> to populate the multi-select for <xsl:value-of select="@name"/> */
        <xsl:call-template name="menu">
          <xsl:with-param name="property" select="."/>
        </xsl:call-template>
      </xsl:for-each>

    </xsl:template>

    <xsl:template name="menu">
      <xsl:param name="property"/>
      <xsl:variable name="ename" select="$property/@entity"/>
      <xsl:variable name="entity" select="//entity[@name=$ename]"/>
          PropertyBag["<xsl:value-of select="concat('all_', $property/@name)"/>"] =
            hibernator.CreateCriteria(typeof(<xsl:value-of select="$property/@entity"/>))<xsl:for-each select="$entity/property[@distinct='user']">
              <xsl:value-of select="concat('.AddOrder( new Order( &#34;', @name, '&#34;, true))')"/>
            </xsl:for-each>.List&lt;<xsl:value-of select="$property/@entity"/>&gt;();
    </xsl:template>

    <xsl:template name="primary-key">
      <!-- return the name of the primary key of the entity with this name -->
      <xsl:param name="entityname"/>
      <xsl:choose>
        <xsl:when test="//entity[@name=$entityname]/@natural-key">
          <xsl:value-of select="//entity[@name=$entityname]/@natural-key"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat( $entityname, 'Id')" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
  </xsl:stylesheet>