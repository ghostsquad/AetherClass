function ItIs-NotIn {
    [cmdletbinding()]
    param (
        [System.Collections.IEnumerable]$Items
    )

    Guard-ArgumentNotNull 'Item' $Items

    $func = {
        param($value)
        return $Items -notcontains $value
    }.GetNewClosure()

    return (ItIs-Expression $func)
}