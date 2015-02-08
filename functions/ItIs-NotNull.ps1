function ItIs-NotNull {
    [cmdletbinding()]
    param ()

    $func = {
        param($value)
        return $value -ne $null
    }

    return (ItIs-Expression $func)
}