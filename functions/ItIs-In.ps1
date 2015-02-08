function ItIs-In {
    [cmdletbinding()]
    param (
        [System.Collections.IEnumerable]$Items
    )

    Guard-ArgumentNotNull 'Item' $Items

    $func = {
        param($value)
        return $Items -contains $value
    }.GetNewClosure()

    return (ItIs-Expression $func)
}