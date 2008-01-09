using System;
using System.Collections.Generic;
using System.Text;

/*
 *    Application Description Framework
 *    DataRequiredException.cs
 *     
 *    (c) 2007 Cygnet Solutions Ltd
 *    
 *    $Author: af $
 *    $Revision: 1.1 $
 */
namespace ADL.Exceptions {
    /// <summary>
    /// An exception to be thrown if an attempt is made to set a required property to null
    /// </summary>
    public class DataRequiredException : DataSuitabilityException {
        public DataRequiredException(String message) : base(message){}
    }
}
