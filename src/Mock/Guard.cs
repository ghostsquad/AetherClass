namespace GpClass.Mock {
    using System;
    using System.Diagnostics;
    using System.Globalization;
    using System.Linq.Expressions;

    using GpClass.Properties;

    /// <summary>
    /// The guard.
    /// </summary>
    [DebuggerStepThrough]
    public static class Guard {
        #region Public Methods and Operators

        /// <summary>
        /// The can be assigned.
        /// </summary>
        /// <param name="reference">
        /// The reference.
        /// </param>
        /// <param name="typeToAssign">
        /// The type to assign.
        /// </param>
        /// <param name="targetType">
        /// The target type.
        /// </param>
        /// <exception cref="ArgumentException">
        /// </exception>
        public static void CanBeAssigned(Expression<Func<object>> reference, Type typeToAssign, Type targetType) {
            if (!targetType.IsAssignableFrom(typeToAssign)) {
                if (targetType.IsInterface) {
                    throw new ArgumentException(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            Resources.TypeNotImplementInterface,
                            typeToAssign,
                            targetType),
                        GetParameterName(reference));
                }

                throw new ArgumentException(
                    string.Format(
                        CultureInfo.CurrentCulture,
                        Resources.TypeNotInheritFromType,
                        typeToAssign,
                        targetType),
                    GetParameterName(reference));
            }
        }

        /// <summary>
        /// Ensures the given <paramref name="value"/> is not null.
        ///     Throws <see cref="ArgumentNullException"/> otherwise.
        /// </summary>
        /// <param name="reference">
        /// The reference.
        /// </param>
        /// <param name="value">
        /// The value.
        /// </param>
        public static void NotNull<T>(Expression<Func<T>> reference, T value) {
            if (value == null) {
                throw new ArgumentNullException(GetParameterName(reference));
            }
        }

        /// <summary>
        /// Ensures the given string <paramref name="value"/> is not null or empty.
        ///     Throws <see cref="ArgumentNullException"/> in the first case, or
        ///     <see cref="ArgumentException"/> in the latter.
        /// </summary>
        /// <param name="reference">
        /// The reference.
        /// </param>
        /// <param name="value">
        /// The value.
        /// </param>
        public static void NotNullOrEmpty(Expression<Func<string>> reference, string value) {
            NotNull(reference, value);
            if (value.Length == 0) {
                throw new ArgumentException(Resources.ArgumentCannotBeEmpty, GetParameterName(reference));
            }
        }

        /// <summary>
        /// Checks an argument to ensure it is in the specified range excluding the edges.
        /// </summary>
        /// <typeparam name="T">
        /// Type of the argument to check, it must be an <see cref="IComparable"/> type.
        /// </typeparam>
        /// <param name="reference">
        /// The expression containing the name of the argument.
        /// </param>
        /// <param name="value">
        /// The argument value to check.
        /// </param>
        /// <param name="from">
        /// The minimun allowed value for the argument.
        /// </param>
        /// <param name="to">
        /// The maximun allowed value for the argument.
        /// </param>
        public static void NotOutOfRangeExclusive<T>(Expression<Func<T>> reference, T value, T from, T to)
            where T : IComparable {
            if (value != null && (value.CompareTo(from) <= 0 || value.CompareTo(to) >= 0)) {
                throw new ArgumentOutOfRangeException(GetParameterName(reference));
            }
        }

        /// <summary>
        /// Checks an argument to ensure it is in the specified range including the edges.
        /// </summary>
        /// <typeparam name="T">
        /// Type of the argument to check, it must be an <see cref="IComparable"/> type.
        /// </typeparam>
        /// <param name="reference">
        /// The expression containing the name of the argument.
        /// </param>
        /// <param name="value">
        /// The argument value to check.
        /// </param>
        /// <param name="from">
        /// The minimun allowed value for the argument.
        /// </param>
        /// <param name="to">
        /// The maximun allowed value for the argument.
        /// </param>
        public static void NotOutOfRangeInclusive<T>(Expression<Func<T>> reference, T value, T from, T to)
            where T : IComparable {
            if (value != null && (value.CompareTo(from) < 0 || value.CompareTo(to) > 0)) {
                throw new ArgumentOutOfRangeException(GetParameterName(reference));
            }
        }

        #endregion

        #region Methods

        /// <summary>
        /// The get parameter name.
        /// </summary>
        /// <param name="reference">
        /// The reference.
        /// </param>
        /// <returns>
        /// The <see cref="string"/>.
        /// </returns>
        private static string GetParameterName(LambdaExpression reference) {
            var member = (MemberExpression)reference.Body;
            return member.Member.Name;
        }

        #endregion
    }
}