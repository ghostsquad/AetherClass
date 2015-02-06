function New-PSClassMock {
    [cmdletbinding(DefaultParameterSetName='PSClass')]
    param (
        [Parameter(Position=0,ParameterSetName='PSClass')]
        [PSObject]$Class,
        [Parameter(Position=0,ParameterSetName='PSClassName')]
        [String]$ClassName,
        [Switch]$Strict
    )

    if($PSCmdlet.ParameterSetName -eq 'PSClass') {
        Guard-ArgumentNotNull 'Class' $Class
    } else {
        Guard-ArgumentNotNull 'ClassName' $ClassName
        $Class = Get-PSClass $ClassName
        if($Class -eq $null) {
            throw (New-Object System.ArgumentException(('A PSClass cannot be found with name: {0}' -f $ClassName)))
        }
    }

    $mock = New-PSObject
    Attach-PSNote $mock '_strict' ([bool]$Strict)
    Attach-PSNote $mock '_originalClass' $Class
    Attach-PSNote $mock '_mockedMethods' @{}
    Attach-PSNote $mock '_mockedProperties' @{}
    Attach-PSNote $mock 'Object' (New-PSObject)
    Attach-PSNote $mock.Object '____mock' $mock

    Attach-PSScriptMethod $mock 'Setup' {
        param (
            [string]$memberName,
            [object]$returnObjectOrMethodDefinition,
            [ref][object]$callbackValue
        )

        $member = $this._originalClass.__Members[$memberName]
        if($member -eq $null) {
            throw (new-object PSMockException("Member with name: $memberName cannot be found to mock!"))
        }

        if($member -is [System.Management.Automation.PSScriptMethod]) {
            if(-not $this._originalClass.__Methods.ContainsKey($memberName)) {
                throw (new-object PSMockException("Method with name: $memberName cannot be found to mock!"))
            }

            Guard-ArgumentValid 'returnObjectOrMethodDefinition' -Test ($returnObjectOrMethodDefinition -is [Scriptblock])

            $methodToMockScript = $this._originalClass.__Methods[$memberName].PSScriptMethod.Script

            try {
                Assert-ScriptBlockParametersEqual $methodToMockScript $returnObjectOrMethodDefinition
            } catch {
                $msg = "Unable to mock method: {0}" -f $memberName
                $exception = (new-object PSMockException($msg, $_))
                throw $exception
            }

            # add the actual mocked script to the mock internals
            $mockMethodInfoClass = Get-PSClass 'PSClass.MockMethodInfo'
            $this._mockedMethods[$memberName] = $mockMethodInfoClass.New($this, $memberName, $returnObjectOrMethodDefinition)

            # replace the method script in the class we are to mock with a call to the mocked script
            # because we are doing a bit of redirection, it allows us to capture information about each method call
            $scriptBlockText = [string]::Format('$this.____mock._mockedMethods[''{0}''].InvokeMethodScript($Args)', $memberName)
            $mockedMethodScript = [ScriptBlock]::Create($scriptBlockText)

            $member = new-object management.automation.PSScriptMethod $memberName,$mockedMethodScript
            $this.Object.psobject.methods.remove($memberName)
            [Void]$this.Object.psobject.methods.add($member)
        }

        if($member -is [System.Management.Automation.PSNoteProperty] `
            -or $member -is [System.Management.Automation.PSScriptProperty]) {

            if(-not $this._originalClass.__Properties.ContainsKey($memberName) -and `
                -not $this._originalClass.__Notes.ContainsKey($memberName)) {
                throw (new-object PSMockException("Note or Property with name: $memberName cannot be found to mock!"))
            }

            $originalProperty = $this.Object.psobject.properties.Item($memberName)

            $getter = { return $returnObjectOrMethodDefinition }.GetNewClosure()

            if($callbackValue -eq $null) {
                $setter = {}
            } else {
                $setter = {param($a) $callbackValue.Value = $a}.GetNewClosure()
            }

            $member = new-object management.automation.PSScriptProperty $memberName,$getter,$setter
            $this.Object.psobject.properties.remove($memberName)
            [Void]$this.Object.psobject.properties.add($member)
        }
    }

    Attach-PSScriptMethod $mock 'SetupMethod' {
        param (
            [string]$methodName
          , [object]$returnObject
        )

        $this.Setup($methodName, $returnObject)
    }

    Attach-PSScriptMethod $mock 'SetupNoteGet' {
        param (
            [string]$noteName
          , [object]$returnObject
        )

        $this.Setup($noteName, $returnObject)
    }

    Attach-PSScriptMethod $mock 'SetupNoteSet' {
        param (
            [string]$noteName
          , [ref][object]$callbackValue
        )

        $this.Setup($noteName, $null, $callbackValue)
    }

    Attach-PSScriptMethod $mock 'SetupPropertyGet' {
        param (
            [string]$propertyName
          , [object]$returnObject
        )

        $this.Setup($propertyName, $returnObject)
    }

    Attach-PSScriptMethod $mock 'SetupPropertySet' {
        param (
            [string]$propertyName
          , [ref][object]$callbackValue
        )

        $this.Setup($propertyName, $null, $callbackValue)
    }

    Attach-PSScriptMethod $mock 'Verify' {
        param (
            [string]$methodName
          , [object[]]$expectations
        )

        function Assert-True {
            param(
                $actualValue,
                $expectation
            )

            $expectationType = $expectation.GetType()
            if($expectationType -is ([scriptblock]) -or $expectationType -is ([System.MulticastDelegate])) {
                $result = $expectation.InvokeReturnAsIs($actualValue)
                if(-not $result) {
                    throw (new-object PSMockException(
                        [string]::Format("Expected {0} to return true for input: {1}", $expectation, $actualValue)))
                }
            }
            else {
                if($actualValue -ne $expectation) {
                    throw (new-object PSMockException(
                        [string]::Format("Expected {0} but found {1}", $expectation, $actualValue)))
                }
            }
        }

        $mockedMethod = $this._mockedMethods[$methodName]
        if($mockedMethod -eq $null) {
            throw (new-object PSMockException(
                [string]::Format("Unable to verify a method [{0}] that has no expectations!",
                    $methodName)))
        }

        foreach($expectation in $expectations) {
            foreach($callArgsCollection in $mockedMethod.Invocations) {
                foreach($callArg in $callArgsCollection){
                    Assert-True $callArg $expectation
                }
            }
        }
    }

    foreach($methodName in $Class.__Methods.Keys) {
        if($Strict) {
            $mockedMethodScript = {
                throw (new-object PSMockException("This Mock is strict and no expectation was set for method ...."))
            }
        } else {
            $mockedMethodScript = {}
        }

        Attach-PSScriptMethod $mock.Object $methodName $mockedMethodScript
    }

    $notesAndPropertyKeys = New-Object System.Collections.Arraylist
    $notesAndPropertyKeys.AddRange($Class.__Properties.Keys)
    $notesAndPropertyKeys.AddRange($Class.__Notes.Keys)

    foreach($propertyName in $notesAndPropertyKeys) {
        Attach-PSProperty $mock.Object $propertyName {} {}
    }

    return $mock
}

if(-not (Get-PSClass 'PSClass.MockMethodInfo')) {
    New-PSClass 'PSClass.MockMethodInfo' {
        note 'PSClassMock'
        note 'Name'
        note 'Script'
        note 'Invocations'

        constructor {
            param($psClassMock, $name, $script = {})
            $this.PSClassMock = $psClassMock
            $this.Name = $name
            $this.Script = $script
            $this.Invocations = (New-Object System.Collections.ArrayList)
        }

        method 'InvokeMethodScript' {
            param($theArgs)

            [void]$this.Invocations.Add($theArgs)

            $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10 = $theArgs
            switch($theArgs.Count) {
                0 {  return $this.Script.InvokeReturnAsIs() }
                1 {  return $this.Script.InvokeReturnAsIs($p1) }
                2 {  return $this.Script.InvokeReturnAsIs($p1, $p2) }
                3 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3) }
                4 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4) }
                5 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5) }
                6 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6) }
                7 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7) }
                8 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) }
                9 {  return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9) }
                10 { return $this.Script.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10) }
                default {
                    throw (new-object PSMockException("PSClassMock does not support more than 10 arguments for a method mock."))
                }
            }
        }
    }
}

if (-not ([System.Management.Automation.PSTypeName]'PSMockException').Type)
{
    Add-Type -WarningAction Ignore -TypeDefinition @"
    using System;
    using System.Management.Automation;

    public class PSMockException : Exception {
        public ErrorRecord ErrorRecord { get; private set; }

        public PSMockException(string message)
            : base(message)
        {
        }

        public PSMockException(string message, ErrorRecord errorRecord)
            : base(message)
        {
            this.ErrorRecord = errorRecord;
        }

        public PSMockException(string message, Exception inner)
            : base(message, inner)
        {
        }
    }
"@
}