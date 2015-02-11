namespace GpClass.Mock {
    using System;
    using System.Management.Automation;

    /// <summary>
    /// The ps mock exception.
    /// </summary>
    public class PSMockException : Exception {
        public enum ExceptionReason
        {
            NoSetup,
            ReturnValueRequired,
            VerificationFailed,
            MoreThanOneCall,
            MoreThanNCalls,
            SetupNever,
            MockConsistencyCheckFailed,
            MockCreationFailed
        }

        private ExceptionReason reason;

        #region Constructors and Destructors

        /// <summary>
        /// Initializes a new instance of the <see cref="PSMockException"/> class.
        /// </summary>
        /// <param name="message">
        /// The message.
        /// </param>
        public PSMockException(string message)
            : base(message) { }

        /// <summary>
        /// Initializes a new instance of the <see cref="PSMockException"/> class.
        /// </summary>
        /// <param name="message">
        /// The message.
        /// </param>
        /// <param name="errorRecord">
        /// The error record.
        /// </param>
        public PSMockException(string message, ErrorRecord errorRecord)
            : base(message) {
            this.ErrorRecord = errorRecord;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="PSMockException"/> class.
        /// </summary>
        /// <param name="message">
        /// The message.
        /// </param>
        /// <param name="inner">
        /// The inner.
        /// </param>
        public PSMockException(string message, Exception inner)
            : base(message, inner) { }

        #endregion

        #region Public Properties

        /// <summary>
        /// Gets the error record.
        /// </summary>
        public ErrorRecord ErrorRecord { get; private set; }

        #endregion
    }
}