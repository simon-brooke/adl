using System;
using System.Collections.Generic;
using System.Text;

/*
 *    Application Description Framework
 *    DataRangeException.cs
 *     
 *    (c) 2007 Cygnet Solutions Ltd
 *    
 *    $Author: af $
 *    $Revision: 1.1 $
 */

namespace ADL.Exceptions {
    /// <summary>
    /// An exception to be thrown if an attempt is made to set a property 
    /// to a value which is unsuitable
    /// </summary>
    public abstract class DataSuitabilityException : Exception {
        public DataSuitabilityException(String message) : base(message) {}
    }
}
