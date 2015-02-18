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
                        $args
                    )

                    [void]$mockDefinition._mockedMethods[$methodName].Calls.Add($callContext)

                    $methodSetupInfo = $mockDefinition._GetMethodSetupInfoThatMeetExpectations($methodName, $args, $true)

                    if($methodSetupInfo -eq $null) {
                        if($Strict) {
                            $msg = "This Mock is strict and no setups were configured for method {0}" -f $methodName
                            throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
                        }

                        return
                    }

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

                    [void]$mockDefinition._mockedProperties[$propertyName].Calls.Add($callContext)

                    $setups = $mockDefinition._mockedProperties[$propertyName].Setups

                    if($setups.Count -gt 0) {
                        return $setups[0].ReturnValue
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

                    [void]$mockDefinition._mockedProperties[$propertyName].Calls.Add($callContext)

                    if($Strict -and $mockDefinition._mockedProperties[$propertyName].Setups.Count -eq 0) {
                        $msg = "This Mock is strict and no setups were configured for setter of property $propertyName"
                        throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
                    }
                }.GetNewClosure()

                $attachSplat = @{
                    InputObject = $theMockObject
                    Name = $propertyName
                    Get = $mockedPropertyGetScript
                    Set = $mockedPropertySetScript
                }

                Attach-PSProperty @attachSplat
            }

            $this.Object = $theMockObject
        }

        method '_GetMemberFromOriginal' {
            param (
                [string]$memberName
            )

            $member = $this._originalClass.__Members[$MemberName]
            if($member -eq $null) {
                $msg = "Member with name: $MemberName cannot be found to mock!"
                throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
            }

            return $member
        }

        method 'Setup' {
            param (
                [string]$MethodName,
                [System.Collections.IEnumerable]$Expressions = @()
            )

            # Rethrow resetting the call-stack so that
            # callers see the exception as happening at
            # this call site.
            # TODO: see how to mangle the stacktrace so
            # that the mock doesn't even show up there.
            try {

                Guard-ArgumentNotNull 'MethodName' $MethodName

                $member = $this._GetMemberFromOriginal($MethodName)

                if($member -isnot [System.Management.Automation.PSScriptMethod]) {
                    $msg = "Member {0} is not a PSScriptMethod." -f $MethodName
                    throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
                }

                $setupInfo = New-PSClassInstance 'GpClass.Mock.MethodSetupInfo' -ArgumentList @(
                    $this,
                    $MethodName,
                    $Expressions
                )

                [Void]$this._mockedMethods[$MethodName].Setups.Add($setupInfo)

                return $setupInfo
            } catch {
                throw $_.Exception.GetBaseException()
            }
        }

        method 'SetupProperty' {
            param (
                [string]$PropertyName,
                [object]$DefaultValue
            )

            # Rethrow resetting the call-stack so that
            # callers see the exception as happening at
            # this call site.
            # TODO: see how to mangle the stacktrace so
            # that the mock doesn't even show up there.
            try {
                Guard-ArgumentNotNull 'PropertyName' $PropertyName
                $member = $this._GetMemberFromOriginal($PropertyName)

                if($member -isnot [System.Management.Automation.PSNoteProperty] `
                    -and $member -isnot [System.Management.Automation.PSScriptProperty]) {

                    $msg = "Member {0} is not a PSScriptProperty or PSNoteProperty." -f $PropertyName
                    throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
                }

                $setupInfo = New-PSClassInstance 'GpClass.Mock.PropertySetupInfo' -ArgumentList @(
                    $this,
                    $PropertyName,
                    $DefaultValue
                )

                [Void]$this._mockedProperties[$PropertyName].Setups.Add($setupInfo)

                return $setupInfo
            } catch {
                throw $_.Exception.GetBaseException()
            }
        }

        method 'Verify' {
            #[System.Diagnostics.DebuggerStepThrough()]
            param (
                [string]$MethodName,
                [System.Collections.IEnumerable]$Expressions = @(),
                [Times]$Times = [Times]::AtLeastOnce(),
                [string]$FailMessage
            )

            Guard-ArgumentNotNull 'MethodName' $MethodName
            Guard-ArgumentNotNull 'Expressions' $Expressions
            Guard-ArgumentNotNull 'Times' $Times

            $Expectations = New-Object System.Collections.ArrayList
            foreach($expression in $Expressions) {
                $msg = 'All objects in collection should be PSClass type GpClass.Mock.Expression'
                Guard-ArgumentValid 'Expressions' $msg (ObjectIs-PSClassInstance $expression -PSClassName 'GpClass.Mock.Expression')
                [Void]$Expectations.Add($expression.Predicate)
            }

            $callCount = 0
            foreach($call in $this._mockedMethods[$methodName].Calls) {
                if($this._ArgumentsMeetExpectations($call.Arguments, $Expectations)) {
                    $callCount++
                }
            }

            ifdebug {
                'callCount: ' + $callCount
                'times: ' + $Times.ToString()
                'timesverify: ' + $Times.Verify($callCount)
            }

            if(-not $Times.Verify($callCount)) {
                # Rethrow resetting the call-stack so that
                # callers see the exception as happening at
                # this call site.
                # TODO: see how to mangle the stacktrace so
                # that the mock doesn't even show up there.
                try {
                    $this._ThrowVerifyException($MethodName,
                        [InvocationType]::MethodCall,
                        $FailMessage,
                        $Expressions,
                        $this._mockedMethods[$MethodName].Setups,
                        $this._mockedMethods[$MethodName].Calls,
                        $Times,
                        $callCount)
                } catch {
                    throw $_.Exception.GetBaseException()
                }
            }
        }

        method 'VerifyGet' {
            #[System.Diagnostics.DebuggerStepThrough()]
            param (
                [string]$PropertyName,
                [Times]$Times = [Times]::AtLeastOnce(),
                [string]$FailMessage
            )

            Guard-ArgumentNotNull 'PropertyName' $PropertyName
            Guard-ArgumentNotNull 'Times' $Times

            $callCount = $this._mockedProperties[$PropertyName].Calls.Count

            if(-not $Times.Verify($callCount)) {
                # Rethrow resetting the call-stack so that
                # callers see the exception as happening at
                # this call site.
                # TODO: see how to mangle the stacktrace so
                # that the mock doesn't even show up there.
                try {
                    $this._ThrowVerifyException($PropertyName,
                        [InvocationType]::PropertyGet,
                        $FailMessage,
                        @(),
                        $this._mockedProperties[$PropertyName].Setups,
                        $this._mockedProperties[$PropertyName].Calls,
                        $Times,
                        $callCount)
                } catch {
                    throw $_.Exception.GetBaseException()
                }
            }
        }

        method 'VerifySet' {
            #[System.Diagnostics.DebuggerStepThrough()]
            param (
                [string]$PropertyName,
                [psobject]$Expression,
                [Times]$Times = [Times]::AtLeastOnce(),
                [string]$FailMessage
            )

            Guard-ArgumentNotNull 'PropertyName' $PropertyName
            if($Expression -ne $null) {
                Guard-ArgumentIsPSClassInstance 'Expression' $Expression 'GpClass.Mock.Expression'
            }
            Guard-ArgumentNotNull 'Times' $Times

            $Expectations = @($Expression.Predicate)

            $callCount = 0
            foreach($call in $this._mockedProperties[$PropertyName].Calls) {
                if($this._ArgumentsMeetExpectations($call.Arguments, $Expectations)) {
                    $callCount++
                }
            }

            if(-not $Times.Verify($callCount)) {
                # Rethrow resetting the call-stack so that
                # callers see the exception as happening at
                # this call site.
                # TODO: see how to mangle the stacktrace so
                # that the mock doesn't even show up there.
                try {
                    $this._ThrowVerifyException($PropertyName,
                        [InvocationType]::PropertySet,
                        $FailMessage,
                        @($Expression),
                        $this._mockedProperties[$PropertyName].Setups,
                        $this._mockedProperties[$PropertyName].Calls,
                        $Times,
                        $callCount)
                } catch {
                    throw $_.Exception.GetBaseException()
                }
            }
        }

        method '_ThrowVerifyException' {
            param (
                [string]$MemberName,
                [InvocationType]$InvocationType,
                [string]$FailMessage,
                [System.Collections.IEnumerable]$Expressions = @(),
                [System.Collections.IEnumerable]$Setups,
                [System.Collections.IEnumerable]$ActualCalls,
                [Times]$Times,
                [int]$CallCount
            )

            $formatSplat = @{
                InvocationType = $InvocationType
                ClassName = [string]::Empty
                MemberName = $MemberName
                ArgumentsList = @($Expressions | %{$_.ToString()})
            }

            $callExpression = (FormatInvocation @formatSplat)

            [string]$msg = $Times.GetExceptionMessage($FailMessage, $callExpression, $CallCount) + `
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

        method '_ArgumentsMeetExpectations' {
            param (
                [object[]]$ArgumentsList = @(),
                [func[object, bool][]]$Expectations = @()
            )

            $invocationMetExpectations = $false

            if($Expectations.Count -eq 0) {
                $invocationMetExpectations = $true
            } elseif ($Expectations.Count -le $ArgumentsList.Count) {
                for($i = 0; $i -lt $ArgumentsList.Count; $i++) {
                    if($i -ge $Expectations.Count) {
                        $invocationMetExpectations = $true
                        break;
                    }

                    $invocationMetExpectations = $Expectations[$i].Invoke($ArgumentsList[$i])
                    if(-not $invocationMetExpectations) {
                        break;
                    }
                }
            }

            return $invocationMetExpectations
        }

        method '_GetMethodSetupInfoThatMeetExpectations' {
            param (
                [string]$methodName,
                [object[]]$ArgumentsList = @(),
                [bool]$First
            )

            $metExpectationsSetupInfoCollection = New-Object System.Collections.ArrayList

            foreach($methodSetupInfo in $this._mockedMethods[$methodName].Setups) {
                if($this._ArgumentsMeetExpectations($ArgumentsList, $methodSetupInfo.Expectations)) {
                    if($First) {
                        return $methodSetupInfo
                    }

                    [void]$metExpectationsSetupInfoCollection.Add($methodSetupInfo)
                }
            }

            if($First) {
                return $null
            } elseif ($metExpectationsSetupInfoCollection.Count -gt 1) {
                return $metExpectationsSetupInfoCollection
            }

            return ,$metExpectationsSetupInfoCollection
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
        note 'Expressions'
        note 'Invocations'
        note 'InvocationType'
        note 'CallbackAction'
        note 'ReturnValue'
        note 'CallCount'

        property 'Expectations' {
            $expectations = @($this.Expressions | %{[func[object,bool]]$_.Predicate})

            if($expectations.Count -gt 1) {
                return $expectations
            } else {
                return ,$expectations
            }
        }

        constructor {
            param (
                $Mock,
                $Name,
                $InvocationType
            )

            $this.Mock = $Mock
            $this.Name = $Name
            $this.InvocationType = $InvocationType
            $this.Expressions = New-Object System.Collections.ArrayList
            [Scriptblock]$this.CallbackAction = {}
            $this.Invocations = New-Object System.Collections.ArrayList
            $this.ReturnValue = $null
        }

        method 'Format' {
            $formatSplat = @{
                InvocationType = $this.InvocationType
                ClassName = $this.Mock._originalClass.__ClassName
                MemberName = $this.Name
                ArgumentsList = @($this.Expressions | %{$_.ToString()})
            }

            return (FormatInvocation @formatSplat)
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

            [Void]$this.Expressions.Add((ItIs-Any ([object])))
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
                [System.Collections.IEnumerable]$Expressions = @()
            )

            Base $Mock $Name [InvocationType]::MethodCall

            $this.Expressions = $Expressions
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
            $formatSplat = @{
                InvocationType = $this.InvocationType
                ClassName = $this.Mock._originalClass.__ClassName
                MemberName = $this.MemberName
                ArgumentsList = $this.Arguments
            }

            return (FormatInvocation @formatSplat)
        }
    }
}

if(-not (Get-PSClass 'GpClass.Mock.Expression')) {
    New-PSClass 'GpClass.Mock.Expression' {
        note _stringRepresentation
        note Predicate

        constructor {
            param (
                [func[object, bool]]$Predicate,
                [string]$Representation
            )

            $this.Predicate = $Predicate
            $this._stringRepresentation = $Representation
        }

        method 'ToString' {
            return $this._stringRepresentation
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