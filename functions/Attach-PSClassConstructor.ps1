# - - - - - - - - - - - - - - - - - - - - - - - -
# Helper function
#   Assigns Constructor script to Class
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassConstructor {
    [cmdletbinding()]
    param (
        [psobject]$Class,

        [Parameter(Position=0)]
        [scriptblock]$scriptblock = $(Throw "Constuctor scriptblock is required.")
    )

    if($Class -eq $null) {
        Write-Debug 'Attempting to get $Class from parent scope (1)'
        $Class = (Get-Variable -name 'Class' -ValueOnly -Scope 1 -ErrorAction Ignore)
        if($Class -eq $null) {
            Write-Debug 'Attempting to get $Class from grandparent scope (2)'
            $Class = (Get-Variable -name 'Class' -ValueOnly -Scope 2 -ErrorAction Ignore)
        }
    }

    if ($Class.__ConstructorScript -ne $null) {
        Throw "Only one Constructor is allowed"
    }

    $Class.__ConstructorScript = $scriptblock
}