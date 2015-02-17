namespace GpClass.Mock {
    using System;
    using System.Diagnostics.CodeAnalysis;
    using System.Globalization;
    using System.Management.Automation;
    using System.Runtime.Serialization;
    using System.Security;

    using GpClass.Properties;

    /// <summary>
    /// Exception thrown by mocks when setups are not matched,
    /// the mock is not properly setup, etc.
    /// </summary>
    /// <remarks>
    /// A distinct exception type is provided so that exceptions
    /// thrown by the mock can be differentiated in tests that
    /// expect other exceptions to be thrown (i.e. ArgumentException).
    /// <para>
    /// Richer exception hierarchy/types are not provided as
    /// tests typically should <b>not</b> catch or expect exceptions
    /// from the mocks. These are typically the result of changes
    /// in the tested class or its collaborators implementation, and
    /// result in fixes in the mock setup so that they dissapear and
    /// allow the test to pass.
    /// </para>
    /// </remarks>
    [Serializable]
    public class PsMockException : Exception {
        public ErrorRecord ErrorRecord { get; private set; }

        private readonly ExceptionReason reason;

        public PsMockException(
            ExceptionReason reason,
            PsMockBehavior behavior,
            //ICallContext invocation,
            ErrorRecord errorRecord)
            : this(reason, behavior, errorRecord, Resources.ResourceManager.GetString(reason.ToString())) {
        }

        public PsMockException(
            ExceptionReason reason,
            PsMockBehavior behavior,
            //ICallContext invocation,
            ErrorRecord errorRecord,
            string message)

            : base(GetMessage(behavior, message)) {
            this.reason = reason;
            this.ErrorRecord = this.ErrorRecord;
        }

        public PsMockException(ExceptionReason reason, string exceptionMessage)
            : base(exceptionMessage) {
            this.reason = reason;
        }

        public ExceptionReason Reason {
            get {
                return this.reason;
            }
        }

        /// <summary>
        /// Indicates whether this exception is a verification fault raised by Verify()
        /// </summary>
        public bool IsVerificationError {
            get {
                return this.reason == ExceptionReason.VerificationFailed;
            }
        }

        private static string GetMessage(PsMockBehavior behavior,
            //ICallContext invocation,
            string message) {

            return string.Format(
                CultureInfo.CurrentCulture,
                Resources.MockExceptionMessage,
                //invocation.Format(),
                behavior,
                message);
        }

        /// <summary>
        /// Supports the serialization infrastructure.
        /// </summary>
        /// <param name="info">Serialization information.</param>
        /// <param name="context">Streaming context.</param>
        protected PsMockException(SerializationInfo info, StreamingContext context)
            : base(info, context) {
            this.reason = (ExceptionReason)info.GetValue("reason", typeof(ExceptionReason));
        }

        /// <summary>
        /// Supports the serialization infrastructure.
        /// </summary>
        /// <param name="info">Serialization information.</param>
        /// <param name="context">Streaming context.</param>
        [SecurityCritical]
        [SuppressMessage("Microsoft.Security", "CA2123:OverrideLinkDemandsShouldBeIdenticalToBase")]
        public override void GetObjectData(SerializationInfo info, StreamingContext context) {
            base.GetObjectData(info, context);
            info.AddValue("reason", this.reason);
        }
    }
}