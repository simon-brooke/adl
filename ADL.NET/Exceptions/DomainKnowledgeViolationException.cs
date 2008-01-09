using System;
using System.Collections.Generic;
using System.Text;

/*
 *    Application Description Framework
 *    DomainKnowledgeViolationException.cs
 *     
 *    (c) 2007 Cygnet Solutions Ltd
 *    
 *    $Author: af $
 *    $Revision: 1.1 $
 */

namespace ADL.Exceptions {
    /// <summary>
    /// An exception to be thrown if a state arises which violates 
    /// some specific knowledge about the application domain (i.e. 
    /// a 'business rule' violation)
    /// </summary>
    public class DomainKnowledgeViolationException : Exception {
        public DomainKnowledgeViolationException(String message) : base(message) { }
    }
}
