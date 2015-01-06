# - - - - - - - - - - - - - - - - - - - - - - - -
# Subfunction: method
#   Add a method script to Class definition or
#   attaches it to the Class if it is static
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassMethod {
    param  (
        [psobject]$Class
      , [string]$name = $(Throw "Method Name is required.")
      , [scriptblock]$script = $(Throw "Method Script is required.")
      , [switch]$static
      , [switch]$override
    )

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
        [Void]$Class.__Members.Add($PSScriptMethod)
    }
}