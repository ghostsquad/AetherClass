function FormatInvocation {
    param (
        [InvocationType]$InvocationType,
        [string]$ClassName,
        [string]$MemberName,
        [object[]]$ArgumentsList
    )

    if(-not [string]::IsNullOrEmpty($ClassName)) {
        $ClassName += "."
    }

    if ($InvocationType -eq [InvocationType]::PropertyGet) {
        return $ClassName + $MemberName;
    }

    if ($InvocationType -eq [InvocationType]::PropertySet) {
        return ($ClassName + $MemberName + " = " + $ArgumentsList[0])
    }

    return ($ClassName + $MemberName + "(" + [string]::Join(", ", $ArgumentsList) + ")")
}