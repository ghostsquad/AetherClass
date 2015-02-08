function ItIs-InRange {
    [cmdletbinding()]
    param (
        [object]$From,
        [object]$To,
        [Range]$RangeKind = ([Range]::Inclusive)
    )

    Guard-ArgumentNotNull 'From' $From
    Guard-ArgumentNotNull 'To' $To

    $func = {
        param($value)

        if($value -eq $null) {
            return $false
        }

        if ($RangeKind -eq [Range]::Exclusive) {
            return $value.CompareTo($From) -gt 0 -and $value.CompareTo($To) -lt 0;
        }

        return $value.CompareTo($From) -ge 0 -and $value.CompareTo($To) -le 0;
    }.GetNewClosure()

    return (ItIs-Expression $func)
}