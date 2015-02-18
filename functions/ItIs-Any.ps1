function ItIs-Any {
    [cmdletbinding()]
    param (
        [Type]$Type
    )

    Guard-ArgumentNotNull 'Type' $Type

    $func = {
        param($value)
        return $value -is $Type
    }.GetNewClosure()

    return (ItIs-Expression $func)
}