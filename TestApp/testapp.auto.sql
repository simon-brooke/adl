 
        -------------------------------------------------------------------------------------------------
        --
        --    Application Description Language Framework
        --
        --    Database for application adltestapp version 
        --    Generated for MS-SQL 2000+ using adl2mssql.xslt 1.2 $
        --
        --    Code generator (c) 2007 Cygnet Solutions Ltd
        --
        -------------------------------------------------------------------------------------------------

    
      use ADL_TestApp;
    

        -------------------------------------------------------------------------------------------------
        --    authentication roles
        -------------------------------------------------------------------------------------------------
    
        execute sp_addrole @rolename = 'public' 
        
        GO
  
        execute sp_addrole @rolename = 'admin' 
        
        GO
  

        -------------------------------------------------------------------------------------------------
        --    primary tables, views and permissions
        -------------------------------------------------------------------------------------------------
    

        -------------------------------------------------------------------------------------------------
        --    primary table person
        -------------------------------------------------------------------------------------------------
        CREATE TABLE  "person"
        (
    
          "person_Id" INT IDENTITY( 1, 1),
          "LastName" VARCHAR( 100)  NOT NULL,
          "ForeNames" VARCHAR( 100)  NOT NULL,
          "Partner" INT,
          "Gender" VARCHAR( 1)  NOT NULL,
          "age" INT ,
          "Address" VARCHAR( 8)
          , 
          PRIMARY KEY( "person_Id")
    
        )

        GO

        ----  permissions  ------------------------------------------------------------------------------
    
        REVOKE ALL ON "person" FROM public
        GO
        
    
        REVOKE ALL ON "person" FROM admin
        GO
        
    

        -------------------------------------------------------------------------------------------------
        --    primary table address
        -------------------------------------------------------------------------------------------------
        CREATE TABLE  "address"
        (
    
          "Number" VARCHAR( 8) ,
          "Postcode" VARCHAR( 10) ,
          "Address1" VARCHAR( 255)  NOT NULL,
          "Address2" VARCHAR( 255) ,
          "Address3" VARCHAR( 255) ,
          "City" VARCHAR( 255) ,
          "County" VARCHAR( 255) 
          , 
          PRIMARY KEY( "Number", "Postcode")
    
        )

        GO

        ----  permissions  ------------------------------------------------------------------------------
    

        -------------------------------------------------------------------------------------------------
        --    link tables  
        -------------------------------------------------------------------------------------------------
    
        -- Problems with responsibility for generating link tables:
        -- @entity = person
        -- $nearside = person
        -- $farside = person_1
        -- farlink = Friends
        -- comparison = '0' 
        -- my responsibility = true

        -------------------------------------------------------------------------------------------------
        --    link table joining person with person
        -------------------------------------------------------------------------------------------------
        CREATE TABLE "LN_person_person"
        (
          "personLink" INT NOT NULL,
          "person_1Link" INT NOT NULL
        )

        GO
          
            
          
        ----  permissions  ------------------------------------------------------------------------------
        
        REVOKE ALL ON LN_person_person FROM public
        GO
          
        REVOKE ALL ON LN_person_person FROM admin
        GO
          
          
        ----  referential integrity  --------------------------------------------------------------------
        
          
        ALTER TABLE "LN_person_person"
            ADD FOREIGN KEY ( "personLink") 
            REFERENCES "person" ON DELETE NO ACTION
            
        GO
  
        ALTER TABLE "LN_person_person"
            ADD FOREIGN KEY ( "person_1Link") 
            REFERENCES "person" ON DELETE CASCADE
            
        GO
  

        -------------------------------------------------------------------------------------------------
        --    primary referential integrity constraints
        -------------------------------------------------------------------------------------------------
    
        ALTER TABLE "person"
            ADD FOREIGN KEY ( "Partner") 
            REFERENCES "person" ON DELETE NO ACTION
            
        GO
  
        ALTER TABLE "person"
            ADD FOREIGN KEY ( "Address") 
            REFERENCES "address" ON DELETE NO ACTION
            
        GO
  
      
        -------------------------------------------------------------------------------------------------
        --    end of file
        -------------------------------------------------------------------------------------------------
  