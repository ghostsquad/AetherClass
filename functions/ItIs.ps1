function ItIs {
    [cmdletbinding()]
    param (
        [object]$InputObject
    )

    Guard-ArgumentNotNull 'InputObject' $InputObject

    $func = {
        param($value)
        return [object]::Equals($value, $InputObject)
    }.GetNewClosure()

    return (ItIs-Expression $func)
}