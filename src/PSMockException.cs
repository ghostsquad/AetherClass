using System;
using System.Collections.Generic;
namespace GpClass
{
    using System;
    using System.Management.Automation;

    public class PSMockException : Exception
    {
        public ErrorRecord ErrorRecord { get; private set; }

        public PSMockException(string message)
            : base(message)
        {
        }

        public PSMockException(string message, ErrorRecord errorRecord)
            : base(message)
        {
            this.ErrorRecord = errorRecord;
        }

        public PSMockException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
}
