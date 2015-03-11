# - - - - - - - - - - - - - - - - - - - - - - - -
# Helper function
#   Add a property to Class definition or
#   attaches it to the Class if it is static
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassProperty {
    [cmdletbinding()]
    param (
        [psobject]$Class,

        [Parameter(Position=0)]
        [string]$name,

        [Parameter(Position=1)]
        [scriptblock]$get,

        [Parameter(Position=2)]
        [scriptblock]$set,

        [switch]$static,
        [switch]$override
    )

    if($Class -eq $null) {
        Write-Debug 'Attempting to get $Class from parent scope (1)'
        $Class = (Get-Variable -name 'Class' -ValueOnly -Scope 1 -ErrorAction Ignore)
        if($Class -eq $null) {
            Write-Debug 'Attempting to get $Class from grandparent scope (2)'
            $Class = (Get-Variable -name 'Class' -ValueOnly -Scope 2 -ErrorAction Ignore)
        }
    }

    if ($static) {
        Attach-PSProperty $Class $name $get $set
    } else {
        if($Class.__Properties[$name] -ne $null) {
            throw (new-object PSClassException("Property with name: $Name cannot be added twice."))
        }

        if($override) {
            $baseProperty = ?: { $Class.__BaseClass -ne $null } { $Class.__BaseClass.__Properties[$name] } { $null }
            if($baseProperty -eq $null) {
                throw (new-object PSClassException("Property with name: $Name cannot be override, as it does not exist on the base class."))
            } elseif($baseProperty.PsScriptProperty.SetterScript -eq $null -xor $set -eq $null){
                throw (new-object PSClassException("Property with name: $Name has setter which does not match the base class setter."))
            }
        }

        $PsScriptProperty = new-object management.automation.PsScriptProperty $Name,$Get,$Set
        $Class.__Properties[$name] = @{PSScriptProperty=$PsScriptProperty;Override=$override}
        [Void]$Class.__Members.Add($Name, $PsScriptProperty)
    }
}