namespace GpClass.Mock {
    using System;
    using System.Globalization;

    using GpClass.Properties;

    /// <include file='Times.xdoc' path='docs/doc[@for="Times"]/*'/>
    public struct Times {
        #region Fields

        private readonly Func<int, bool> evaluator;

        private readonly int from;

        private readonly string messageFormat;

        private readonly int to;

        private readonly string stringRepresentation;

        #endregion

        #region Constructors and Destructors

        private Times(Func<int, bool> evaluator, int from, int to, string messageFormat, string stringRepresentation)
        {
            this.evaluator = evaluator;
            this.from = from;
            this.to = to;
            this.messageFormat = messageFormat;
            this.stringRepresentation = stringRepresentation;
        }

        #endregion

        #region Public Methods and Operators

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.AtLeast"]/*'/>
        public static Times AtLeast(int callCount) {
            Guard.NotOutOfRangeInclusive(() => callCount, callCount, 1, int.MaxValue);

            return new Times(
                c => c >= callCount,
                callCount,
                int.MaxValue,
                Resources.NoMatchingCallsAtLeast,
                string.Format(Resources.AtLeast, callCount));
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.AtLeastOnce"]/*'/>
        public static Times AtLeastOnce() {
            return new Times(c => c >= 1, 1, int.MaxValue, Resources.NoMatchingCallsAtLeastOnce, Resources.AtLeastOnce);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.AtMost"]/*'/>
        public static Times AtMost(int callCount) {
            Guard.NotOutOfRangeInclusive(() => callCount, callCount, 0, int.MaxValue);

            return new Times(
                c => c >= 0 && c <= callCount,
                0,
                callCount,
                Resources.NoMatchingCallsAtMost,
                string.Format(Resources.AtMost, callCount));
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.AtMostOnce"]/*'/>
        public static Times AtMostOnce() {
            return new Times(c => c >= 0 && c <= 1, 0, 1, Resources.NoMatchingCallsAtMostOnce, Resources.AtMostOnce);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.Between"]/*'/>
        public static Times Between(int callCountFrom, int callCountTo, Range rangeKind) {
            if (rangeKind == Range.Exclusive) {
                Guard.NotOutOfRangeExclusive(() => callCountFrom, callCountFrom, 0, callCountTo);
                if (callCountTo - callCountFrom == 1) {
                    throw new ArgumentOutOfRangeException("callCountTo");
                }

                return new Times(
                    c => c > callCountFrom && c < callCountTo,
                    callCountFrom,
                    callCountTo,
                    Resources.NoMatchingCallsBetweenExclusive,
                    string.Format(Resources.Between, callCountFrom, callCountTo, rangeKind));
            }

            Guard.NotOutOfRangeInclusive(() => callCountFrom, callCountFrom, 0, callCountTo);
            return new Times(
                c => c >= callCountFrom && c <= callCountTo,
                callCountFrom,
                callCountTo,
                Resources.NoMatchingCallsBetweenInclusive,
                string.Format(Resources.Between, callCountFrom, callCountTo, rangeKind));
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.Exactly"]/*'/>
        public static Times Exactly(int callCount) {
            Guard.NotOutOfRangeInclusive(() => callCount, callCount, 0, int.MaxValue);

            return new Times(
                c => c == callCount,
                callCount,
                callCount,
                Resources.NoMatchingCallsExactly,
                string.Format(Resources.Exactly, callCount));
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.Never"]/*'/>
        public static Times Never() {
            return new Times(c => c == 0, 0, 0, Resources.NoMatchingCallsNever, Resources.Never);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.Once"]/*'/>
        public static Times Once() {
            return new Times(c => c == 1, 1, 1, Resources.NoMatchingCallsOnce, Resources.Once);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.op_Equality"]/*'/>
        public static bool operator ==(Times left, Times right) {
            return left.Equals(right);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.op_Inequality"]/*'/>
        public static bool operator !=(Times left, Times right) {
            return !left.Equals(right);
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.Equals"]/*'/>
        public override bool Equals(object obj) {
            if (obj is Times) {
                var other = (Times)obj;
                return this.from == other.from && this.to == other.to;
            }

            return false;
        }

        /// <include file='Times.xdoc' path='docs/doc[@for="Times.GetHashCode"]/*'/>
        public override int GetHashCode() {
            return this.from.GetHashCode() ^ this.to.GetHashCode();
        }

        #endregion

        #region Methods

        public string GetExceptionMessage(string failMessage, string expression, int callCount) {
            return string.Format(
                CultureInfo.CurrentCulture,
                this.messageFormat,
                failMessage,
                expression,
                this.from,
                this.to,
                callCount);
        }

        public override string ToString() {
            return this.stringRepresentation;
        }

        public bool Verify(int callCount) {
            return this.evaluator(callCount);
        }

        #endregion
    }
}