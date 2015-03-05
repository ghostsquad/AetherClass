namespace Aether.Class.Mock {
    /// <summary>
    /// Options to customize the behavior of the psmock.
    /// </summary>
    public enum PsMockBehavior {
        /// <summary>
        /// Causes the mock to always throw
        /// an exception for invocations that don't have a
        /// corresponding setup.
        /// </summary>
        Strict,

        /// <summary>
        /// Will never throw exceptions, returning null for all calls.
        /// This is currently a limitation PSClass, as return types
        /// are not recorded or verified.
        /// </summary>
        Loose,

        /// <summary>
        /// Default mock behavior, which equals <see cref="Loose"/>.
        /// </summary>
        Default = Loose,
    }
}