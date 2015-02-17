#TODO
# Convert all PSMockException Messages to use GpClass.Properties.Resources

if(-not (Get-PSClass 'GpClass.Mock')) {
    New-PSClass 'GpClass.Mock' {
        note '_strict' $false
        note '_originalClass'
        note '_mockedMethods'
        note '_mockedProperties'
        note 'Object'

        constructor {
            param (
                [psobject]$Class,
                [bool]$Strict
            )

            Guard-ArgumentIsPSClassDefinition 'Class' $Class

            $this._originalClass = $Class
            $this._mockedMethods = @{}
            $this._mockedProperties = @{}

            $theMockObject = New-PSObject
            Attach-PSNote $theMockObject '____mock____' $this

            $mockDefinition = $this

            foreach($methodName in $Class.__Methods.Keys) {
                $this._mockedMethods[$methodName] = New-PSClassInstance 'GpClass.Mock.MemberInfo'

                $mockedMethodScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $callContext = New-PSClassInstance 'GpClass.Mock.CallContext' -ArgumentList @(
                        $mockDefinition,
                        $methodName,
                        [InvocationType]::MethodCall,
                        $Args
                    )

                    $mockDefinition._mockedMethods[$methodName].Calls.Add($callContext)
                    $methodSetupInfo = $mockDefinition._GetMethodSetupInfosThatMetExpectations($methodName, $true)
                    if($methodSetupInfo -ne $null) {
                        [Void]$methodSetupInfo.Invocations.Add($callContext)
                        if($methodSetupInfo.ExceptionToThrow -ne $null) {
                            throw $methodSetupInfo.ExceptionToThrow
                        }

                        $private:p1, $private:p2, $private:p3, $private:p4, $private:p5, $private:p6, `
                            $private:p7, $private:p8, $private:p9, $private:p10 = $args
                        switch($args.Count) {
                            0 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs()) }
                            1 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1)) }
                            2 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2)) }
                            3 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3)) }
                            4 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4)) }
                            5 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5)) }
                            6 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6)) }
                            7 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7)) }
                            8 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)) }
                            9 {  [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)) }
                            10 { [Void]($methodSetupInfo.CallBackAction.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10)) }
                            default {
                                throw (new-object PSClassException("PSClassMock Callbacks do not support more than 10 arguments."))
                            }
                        }

                        return $methodSetupInfo.ReturnValue
                    }

                    if($Strict) {
                        $msg = "This Mock is strict and no expectations were set for method {0}" -f $methodName
                        throw (new-object PSMockException($msg))
                    }
                }.GetNewClosure()

                Attach-PSScriptMethod $theMockObject $methodName $mockedMethodScript
            }

            $notesAndPropertyKeys = New-Object System.Collections.Arraylist
            $notesAndPropertyKeys.AddRange($Class.__Properties.Keys)
            $notesAndPropertyKeys.AddRange($Class.__Notes.Keys)

            foreach($propertyName in $notesAndPropertyKeys) {
                $this._mockedProperties[$propertyName] = New-PSClassInstance 'GpClass.Mock.MemberInfo'

                $mockedPropertyGetScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $callContext = New-PSClassInstance 'GpClass.Mock.CallContext' -ArgumentList @(
                        $mockDefinition,
                        $propertyName,
                        [InvocationType]::PropertyGet
                    )
                    $mockDefinition._mockedProperties[$propertyName].Calls.Add($callContext)

                    $propertySetupInfoCollection = $mockDefinition._mockedProperties[$propertyName].Setups
                    $condition = {ObjectIs-PSClassInstance $_ 'GpClass.Mock.PropertySetupInfo'}
                    if(Where-Any -InputObject $propertySetupInfoCollection -Condition $condition) {
                        [Void]$propertySetupInfo.Invocations.Add($callContext)
                        return $propertySetupInfo.ReturnValue
                    }

                    if($Strict) {
                        $msg = "This Mock is strict and no expectation was set for property $propertyName"
                        throw (new-object PSMockException($msg))
                    }
                }.GetNewClosure()

                $mockedPropertySetScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $callContext = New-PSClassInstance 'GpClass.Mock.CallContext' -ArgumentList @(
                        $mockDefinition,
                        $propertyName,
                        [InvocationType]::PropertySet,
                        $Args[0]
                    )

                    $mockDefinition._mockedProperties[$propertyName].Calls.Add($callContext)

                    $propertySetupInfoCollection = $mockDefinition._mockedProperties[$propertyName].Setups
                    $condition = {ObjectIs-PSClassInstance $_ 'GpClass.Mock.PropertySetupInfo'}
                    if(Where-Any -InputObject $propertySetupInfoCollection -Condition $condition) {
                        [Void]$propertySetupInfo.Invocations.Add($callContext)
                        return $propertySetupInfo.ReturnValue
                    }

                    if($Strict) {
                        $msg = "This Mock is strict and no expectation was set for property $propertyName"
                        throw (new-object PSMockException($msg))
                    }
                }.GetNewClosure()

                Attach-PSProperty $theMockObject $propertyName $mockedPropertyGetScript $mockedPropertySetScript
            }

            $this.Object = $theMockObject
        }

        method '_GetMemberFromOriginal' {
            param (
                [string]$memberName
            )

            $member = $this._originalClass.__Members[$MemberName]
            if($member -eq $null) {
                throw (new-object PSMockException("Member with name: $MemberName cannot be found to mock!"))
            }

            return $member
        }

        method 'Setup' {
            param (
                [string]$MethodName,
                [func[object, bool][]]$Expectations = @()
            )

            Guard-ArgumentNotNull 'MethodName' $MethodName

            $member = $this._GetMemberFromOriginal($MethodName)

            if($member -isnot [System.Management.Automation.PSScriptMethod]) {
                throw (new-object PSMockException(("Member {0} is not a PSScriptMethod." -f $MethodName)))
            }

            $setupInfo = New-PSClassInstance 'GpClass.Mock.MethodSetupInfo' -ArgumentList @(
                $this,
                $MethodName,
                $Expectations
            )

            [Void]$this._mockedMethods[$MethodName].Setups.Add($setupInfo)

            return $setupInfo
        }

        method 'SetupMethod' {
            param (
                [string]$MethodName,
                [func[object, bool][]]$Expectations = @()
            )

            return $this.Setup($MethodName, $Expectations)
        }

        method 'SetupProperty' {
            param (
                [string]$PropertyName,
                [object]$DefaultValue
            )

            Guard-ArgumentNotNull 'PropertyName' $PropertyName
            $member = $this._GetMemberFromOriginal($PropertyName)

            if($member -isnot [System.Management.Automation.PSNoteProperty] `
                -and $member -isnot [System.Management.Automation.PSScriptProperty]) {

                $msg = "Member {0} is not a PSScriptProperty or PSNoteProperty." -f $PropertyName
                throw (new-object PSMockException($msg))
            }

            $setupInfo = New-PSClassInstance 'GpClass.Mock.PropertySetupInfo' -ArgumentList @(
                $this,
                $PropertyName,
                $DefaultValue
            )

            [Void]$this._mockedProperties[$PropertyName].Add($setupInfo)

            return $setupInfo
        }

        method 'Verify' {
            param (
                [string]$MethodName,
                [func[object, bool][]]$Expectations = @(),
                [Times]$Times = [Times]::AtLeastOnce(),
                [string]$FailMessage
            )

            Guard-ArgumentNotNull 'MethodName' $MethodName
            Guard-ArgumentNotNull 'Expectations' $Expectations
            Guard-ArgumentNotNull 'Times' $Times

            $callCount = ($this._GetMethodSetupInfosThatMetExpectations($methodName, $false)).Count

            ifdebug {
                'callCount: ' + $callCount
                'times: ' + $Times.ToString()
                'timesverify: ' + $Times.Verify($callCount)
            }

            if(-not $Times.Verify($callCount)) {
                $this._ThrowVerifyException($MethodName,
                    $FailMessage,
                    $Expectations,
                    $this._mockedMethods[$MethodName].Setups,
                    $this._mockedMethods[$MethodName].Calls,
                    $Times,
                    $callCount)
            }
        }

        method 'VerifyGet' {
            param (
                [string]$MemberName,
                [Times]$Times = [Times]::AtLeastOnce()
            )

            Guard-ArgumentNotNull 'MemberName' $MemberName
            Guard-ArgumentNotNull 'Times' $Times

            #TODO
        }

        method 'VerifySet' {
            param (
                [string]$MemberName,
                [func[object, bool]]$Expectation,
                [Times]$Times = [Times]::AtLeastOnce()
            )

            Guard-ArgumentNotNull 'MemberName' $MemberName
            Guard-ArgumentNotNull 'Expectation' $Expectation
            Guard-ArgumentNotNull 'Times' $Times

            #TODO
        }

        method '_ThrowVerifyException' {
            param (
                [string]$MemberName,
                [string]$FailMessage,
                [func[object, bool][]]$Expectations = @(),
                [System.Collections.IEnumerable]$Setups,
                [System.Collections.IEnumerable]$ActualCalls,
                [Times]$Times,
                [int]$CallCount
            )

            $Expression = $MemberName + "(" + (ConvertExpectationsToExpressionString $Expectations)+ ")"

            [string]$msg = $Times.GetExceptionMessage($FailMessage, $Expression, $CallCount) + `
                [environment]::NewLine + $this._FormatSetupsInfo($Setups) + `
                [environment]::NewLine + $this._FormatInvocations($ActualCalls)

            throw (New-Object PSMockException([ExceptionReason]::VerificationFailed, $msg))
        }

        method '_FormatSetupsInfo' {
            param (
                [System.Collections.IEnumerable]$Setups
            )

            $expressionSetups = @($Setups | %{$_.Format()})

            return (?: { $expressionSetups.Count -eq 0 } `
               { "No setups configured." } `
               { [Environment]::NewLine `
                    + "Configured setups:" `
                    + [Environment]::NewLine `
                    + [string]::Join([Environment]::NewLine, $expressionSetups) })
        }

        method '_FormatInvocations' {
            param (
                [System.Collections.IEnumerable]$Invocations
            )

            $formattedInvocations = @($Invocations | %{$_.Format()})

            return (?: { $formattedInvocations.Count -eq 0 } `
               { "No invocations performed." } `
               { [Environment]::NewLine `
                    + "Performed invocations:" `
                    + [Environment]::NewLine `
                    + [string]::Join([Environment]::NewLine, $formattedInvocations) })
        }

        method '_GetMethodSetupInfosThatMetExpectations' {
            param (
                $methodName,
                $StopOnFirst = $false
            )

            $MetExpectationsSetupInfoCollection = @()

            $methodSetupInfoCollection = $this._mockedMethods[$methodName].Setups
            $callCollection = $this._mockedMethods[$methodName].Calls

            #breakpoint
            ifdebug {
                'setupct: ' + $methodSetupInfoCollection.count
                'callct: ' + $callCollection.count
            }

            foreach($methodSetupInfo in $methodSetupInfoCollection) {
                foreach($call in $callCollection) {
                    $invocationMetExpectations = $false

                    ifdebug {
                        'expct: ' + $methodSetupInfo.Expectations.Count
                        'argct: ' + $call.Arguments.Count
                    }

                    if($methodSetupInfo.Expectations.Count -eq 0) {
                        $invocationMetExpectations = $true
                        ifdebug {
                            'expectations met because expectations.count == 0'
                        }
                    } elseif($methodSetupInfo.Expectations.Count -le $call.Arguments.Count) {
                        for($i = 0; $i -lt $call.Arguments.Count; $i++) {
                            if($i -ge $methodSetupInfo.Expectations.Count) {
                                ifdebug {
                                    'expectations met because more args than expectations'
                                }
                                $invocationMetExpectations = $true
                                break;
                            }

                            $invocationMetExpectations = $methodSetupInfo.Expectations[$i].Invoke($call.Arguments[$i])
                            if(-not $invocationMetExpectations) {
                                ifdebug {
                                    'expectation failed'
                                }
                                break;
                            }
                        }
                    }

                    if($invocationMetExpectations) {
                        if($StopOnFirst) {
                            return $methodSetupInfo
                        }

                        $MetExpectationsSetupInfoCollection += $methodSetupInfo
                    }
                }
            }

            ifdebug {
                'MetExpectationsSetupInfoCollection.count: ' + $MetExpectationsSetupInfoCollection.count
            }

            if($MetExpectationsSetupInfoCollection.Count -gt 1) {
                return $MetExpectationsSetupInfoCollection
            }

            return ,$MetExpectationsSetupInfoCollection
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.MemberInfo')) {
    New-PSClass 'GpClass.Mock.MemberInfo' {
        note Setups
        note Calls

        constructor {
            $this.Setups = New-Object System.Collections.ArrayList
            $this.Calls = New-Object System.Collections.ArrayList
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.SetupInfo')) {
    New-PSClass 'GpClass.Mock.SetupInfo' {
        note 'Mock'
        note 'Name'
        note 'Expectations'
        note 'Invocations'
        note 'InvocationType'
        note 'CallbackAction'
        note 'ReturnValue'
        note 'CallCount'

        constructor {
            param (
                $Mock,
                $Name,
                $InvocationType
            )

            $this.Mock = $Mock
            $this.Name = $Name
            $this.InvocationType = $InvocationType
            $this.Expectations = New-Object 'System.Collections.Generic.List[func[object, bool]]'
            [Scriptblock]$this.CallbackAction = {}
            $this.Invocations = New-Object System.Collections.ArrayList
            $this.ReturnValue = $null
        }

        method 'Format' {
            if ($this.InvocationType -eq [InvocationType]::PropertySet) {
                return ($this.Mock._originalClass.__ClassName + "." + `
                    $this.Name + " = " + (ConvertExpectationsToExpressionString $this.Expectations))
            }

            return ($this.Mock._originalClass.__ClassName + "." + $this.Name + "(" + `
                (ConvertExpectationsToExpressionString $this.Expectations) + ")")
        }

        method 'CallBack' {
            param (
                [Scriptblock]$Action
            )

            Guard-ArgumentNotNull 'Action' $Action

            $this.CallBackAction = $Action
            return $this
        }

        method 'Returns' {
            param (
                [Object]$Value
            )

            $this.ReturnValue = $Value
            return $this
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.PropertySetupInfo')) {
    New-PSClass 'GpClass.Mock.PropertySetupInfo' -Inherit 'GpClass.Mock.SetupInfo' {
        constructor {
            param (
                $Mock,
                $Name,
                $DefaultValue
            )

            Base $Mock $Name [InvocationType]::PropertySet

            [Void]$this.Expectations.Add((ItIs-Any ([object])))
            $this.ReturnValue = $DefaultValue
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.MethodSetupInfo')) {
    New-PSClass 'GpClass.Mock.MethodSetupInfo' -Inherit 'GpClass.Mock.SetupInfo' {
        note 'ExceptionToThrow'

        constructor {
            param (
                $Mock,
                $Name,
                [func[object, bool][]]$Expectations = @()
            )

            Base $Mock $Name [InvocationType]::MethodCall

            [Void]$this.Expectations.AddRange($Expectations)
            $this.ExceptionToThrow = $null
        }

        method 'Throws' {
            param (
                [Exception]$Exception
            )

            Guard-ArgumentNotNull 'Exception' $Exception

            $this.ExceptionToThrow = $Exception
            return $this
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.CallContext')) {
    New-PSClass 'GpClass.Mock.CallContext' {
        note Mock
        note MemberName
        note InvocationType
        note Arguments

        constructor {
            param (
                $Mock,
                $MemberName,
                [InvocationType]$InvocationType,
                [object[]]$Arguments = @()
            )

            $this.Mock = $Mock
            $this.MemberName = $MemberName
            $this.InvocationType = $InvocationType
            $this.Arguments = $Arguments
        }

        method 'Format' {
            if ($this.InvocationType -eq [InvocationType]::PropertyGet) {
                return $this.Mock._originalClass.__ClassName + "." + $this.MemberName;
            }

            if ($this.InvocationType -eq [InvocationType]::PropertySet) {
                return ($this.Mock._originalClass.__ClassName + "." + `
                    $this.MemberName + " = " + $this.Arguments[0])
            }

            return ($this.Mock._originalClass.__ClassName + "." + $this.MemberName + "(" + `
                [string]::Join(", ", $this.Arguments) + ")")
        }
    }
}

function New-PSClassMock {
    [cmdletbinding(DefaultParameterSetName='PSClass')]
    param (
        [Parameter(Position=0,ParameterSetName='PSClass')]
        [PSObject]$Class,
        [Parameter(Position=0,ParameterSetName='PSClassName')]
        [String]$ClassName,
        [Switch]$Strict
    )

    if($PSCmdlet.ParameterSetName -eq 'PSClassName') {
        Guard-ArgumentNotNull 'ClassName' $ClassName
        $Class = Get-PSClass $ClassName
        if($Class -eq $null) {
            throw (New-Object System.ArgumentException(('A PSClass cannot be found with name: {0}' -f $ClassName)))
        }
    }

    return New-PSClassInstance 'GpClass.Mock' -ArgumentList @(
        $Class,
        $Strict
    )
}