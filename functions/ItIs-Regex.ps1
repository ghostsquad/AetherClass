function ItIs-Regex {
    [cmdletbinding()]
    param (
        [string]$Pattern,
        [RegexOptions]$Options = [RegexOptions]::None
    )

    Guard-ArgumentNotNull 'Pattern' $Pattern

    $func = {
        param($value)
        if($value -isnot [string]) {
            return $false
        }
        $re = New-Object System.Text.RegularExpressions.Regex($Pattern, $Options)
        return $re.IsMatch($value)
        return $Items -notcontains $value
    }.GetNewClosure()

    return (ItIs-Expression $func)
}