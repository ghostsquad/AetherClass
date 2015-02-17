function ItIs-Any {
    [cmdletbinding()]
    param (
        [Type]$Type
    )

    ifdebug {
        'itis-any'
        $cmdFrame = (Get-PSCallStack)[1]
        $cmdExpression = $cmdFrame.Command + $cmdFrame.Arguments
        $cmdExpression
    }

    Guard-ArgumentNotNull 'Type' $Type

    $func = {
        param($value)
        return $value -is $Type
    }.GetNewClosure()

    return (ItIs-Expression $func)
}