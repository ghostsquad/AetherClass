function ThrowVerifyException {
    param (
        [string]$MemberName,
        [System.MulticastDelegate]$Delegate,
        [Ienumerable[psobject]]$Setups,
        [Ienumerable[psobject]]$ActualCalls,
        [Times]$Times,
        [int]$CallCount
    )
}