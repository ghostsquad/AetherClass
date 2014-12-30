# - - - - - - - - - - - - - - - - - - - - - - - -
# Helper function
#   Assigns Constructor script to Class
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassConstructor {
    param (
        [psobject]$Class
      , [scriptblock]$scriptblock = $(Throw "Constuctor scriptblock is required.")
    )

    if ($Class.__ConstructorScript -ne $null) {
        Throw "Only one Constructor is allowed"
    }

    $Class.__ConstructorScript = $scriptblock
}