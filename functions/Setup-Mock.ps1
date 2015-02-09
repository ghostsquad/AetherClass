function Setup-Mock {
    [cmdletbinding(DefaultParameterSetName="Method")]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$Mock,

        [parameter(position=0)]
        [alias("m", "Member", "Method", "Note", "Property")]
        [string]$MemberName,

        [parameter(position=1)]
        [alias("e")]
        [func[object,bool][]]$Expectations = (New-Object 'func[object, bool][]'(0)),

        [parameter()]
        [alias("p")]
        [switch]$PassThru,

        [SetupType]$Type = ([SetupType]::Method)
    )

    Guard-ArgumentIsPSClass 'Mock' $Mock 'GpClass.Mock'
    Guard-ArgumentNotNullOrEmpty 'MemberName' $MemberName
    Guard-ArgumentNotNull 'Expectations' $Expectations
    Guard-ArgumentNotNull 'Type' $Type

    $member = $this._originalClass.__Members[$MemberName]
    if($member -eq $null) {
        throw (new-object PSMockException("Member with name: $MemberName cannot be found to mock!"))
    }

    switch($Type) {
        ([SetupType]::Method) {

        }

        ([SetupType]::Get) {

        }

        ([SetupType]::Set) {

        }

        default {
            throw (new-object PSMockException("Member with name: $MemberName cannot be found to mock!"))
        }
    }



    if($member -is [System.Management.Automation.PSScriptMethod]) {
        if(-not $this._originalClass.__Methods.ContainsKey($MemberName)) {
            throw (new-object PSMockException("Method with name: $memberName cannot be found to mock!"))
        }

        Guard-ArgumentValid 'returnObjectOrMethodDefinition' -Test ($returnObjectOrMethodDefinition -is [Scriptblock])

        $methodToMockScript = $this._originalClass.__Methods[$MemberName].PSScriptMethod.Script

        try {
            Assert-ScriptBlockParametersEqual $methodToMockScript $returnObjectOrMethodDefinition
        } catch {
            $msg = "Unable to mock method: {0}" -f $MemberName
            $exception = (new-object PSMockException($msg, $_))
            throw $exception
        }

        # add the actual mocked script to the mock internals
        $mockMethodInfoClass = Get-PSClass 'PSClass.MockMethodInfo'
        $this._mockedMethods[$MemberName] = $mockMethodInfoClass.New($this, $MemberName, $returnObjectOrMethodDefinition)

        # replace the method script in the class we are to mock with a call to the mocked script
        # because we are doing a bit of redirection, it allows us to capture information about each method call
        $scriptBlockText = [string]::Format('$this.____mock._mockedMethods[''{0}''].InvokeMethodScript($Args)', $MemberName)
        $mockedMethodScript = [ScriptBlock]::Create($scriptBlockText)

        $member = new-object management.automation.PSScriptMethod $MemberName,$mockedMethodScript
        $this.Object.psobject.methods.remove($MemberName)
        [Void]$this.Object.psobject.methods.add($member)
    }

    if($member -is [System.Management.Automation.PSNoteProperty] `
        -or $member -is [System.Management.Automation.PSScriptProperty]) {

        if(-not $this._originalClass.__Properties.ContainsKey($MemberName) -and `
            -not $this._originalClass.__Notes.ContainsKey($MemberName)) {
            throw (new-object PSMockException("Note or Property with name: $MemberName cannot be found to mock!"))
        }

        $originalProperty = $this.Object.psobject.properties.Item($MemberName)

        $getter = { return $returnObjectOrMethodDefinition }.GetNewClosure()

        if($callbackValue -eq $null) {
            $setter = {}
        } else {
            $setter = {param($a) $callbackValue.Value = $a}.GetNewClosure()
        }

        $member = new-object management.automation.PSScriptProperty $MemberName,$getter,$setter
        $this.Object.psobject.properties.remove($MemberName)
        [Void]$this.Object.psobject.properties.add($member)
    }

    if($PassThru) {
        return $Mock
    }
}