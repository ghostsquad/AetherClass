# - - - - - - - - - - - - - - - - - - - - - - - -
# Helper function
#   Adds Notes record to class if non-static
# - - - - - - - - - - - - - - - - - - - - - - - -
function Attach-PSClassNote {
    param (
        [psobject]$Class
      , [string]$name = $(Throw "Note Name is required.")
      , [object]$value
      , [switch]$static
      , [switch]$forceValueAssignment
    )

    if ($static) {
        Attach-PSNote $Class $name $value
    } else {
        if($Class.__Notes[$name] -ne $null) {
            throw (new-object PSClassException("Note with name: $Name cannot be added twice."))
        }

        if($Class.__BaseClass -ne $null -and $Class.__BaseClass.__Notes[$name] -ne $null) {
            throw (new-object PSClassException("Note with name: $Name cannot be added, as it already exists on the base class."))
        }

        if(-not $forceValueAssignment `
            -and $Value -ne $null `
            -and -not $Value.GetType().IsValueType `
            -and -not $Value.GetType() -eq [string]) {

            $msg = "Currently only ValueTypes are supported for the default value of a note."
            $msg += "`nTo use a reference type, assign the value using the constructor"
            throw (new-object PSClassException($msg))
        }

        $PSNoteProperty = new-object management.automation.PSNoteProperty $Name,$Value
        $Class.__Notes[$name] = @{PSNoteProperty=$PSNoteProperty;}
        [Void]$Class.__Members.Add($PSNoteProperty)
    }
}