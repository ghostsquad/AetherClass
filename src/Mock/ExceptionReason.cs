namespace Aether.Class.Mock {
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
}