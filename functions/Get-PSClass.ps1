function Get-PSClass {
    param (
        [string]$name
    )

    return $Global:__PSClassDefinitions__[$name]
}