function AssertMemberType {
    param (
        [System.Management.Automation.PSMemberInfo]$member,
        [Type]$memberType
    )

    if($member -isnot $memberType) {
        $msg = "Member {0} is not a {1}." -f $member.Name, $memberType.Name
        throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
    }
}