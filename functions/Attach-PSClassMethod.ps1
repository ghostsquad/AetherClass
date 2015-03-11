# - - - - - - - - - - - - - - - - - - - - - - - -
# Helper function
#   Add a method script to Class definition or
#   attaches it to the Class if it is static
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassMethod {
    [cmdletbinding()]
    param  (
        [psobject]$Class,

        [Parameter(Position=0)]
        [string]$name = $(Throw "Method Name is required."),

        [Parameter(Position=1)]
        [scriptblock]$script = $(Throw "Method Script is required."),

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
        Attach-PSScriptMethod $Class $name $script
    } else {
        if($Class.__Methods[$name] -ne $null) {
            throw (new-object PSClassException("Method with name: $Name cannot be added twice."))
        }

        if($override) {
            $objectVirtualMethodNames = [type]::GetType('System.Object').GetMembers() | ?{$_.IsVirtual} | %{$_.Name}
            if($objectVirtualMethodNames -notcontains $name) {
                $baseMethod = ?: { $Class.__BaseClass -ne $null } { $Class.__BaseClass.__Methods[$name] } { $null }
                if($baseMethod -eq $null) {
                    throw (new-object PSClassException("Method with name: $Name cannot be overridden, as it does not exist on the base class."))
                } else {
                    Assert-ScriptBlockParametersEqual $script $baseMethod.PSScriptMethod.Script
                }
            }
        }

        $PSScriptMethod = new-object management.automation.PSScriptMethod $Name,$script
        $Class.__Methods[$name] = @{PSScriptMethod=$PSScriptMethod;Override=$override}
        [Void]$Class.__Members.Add($Name, $PSScriptMethod)
    }
}