namespace GpClass {
    using System;
    using System.Management.Automation;

    public class PSClassException : Exception {
        #region Constructors and Destructors

        public PSClassException(string message)
            : base(message) {
        }

        public PSClassException(string message, ErrorRecord errorRecord)
            : base(message) {
            this.ErrorRecord = errorRecord;
        }

        public PSClassException(string message, Exception inner)
            : base(message, inner) {
        }

        #endregion

        #region Public Properties

        public ErrorRecord ErrorRecord { get; private set; }

        #endregion
    }
}