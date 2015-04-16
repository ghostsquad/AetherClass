#TODO
# Convert all PSMockException Messages to use Aether.Class.Properties.Resources

if(-not (Get-PSClass 'Aether.Class.Mock')) {
    New-PSClass 'Aether.Class.Mock' {
        note '_strict' $false
        note '_originalClass'
        note '_originalClassHierarchyMembers'
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
            $this._originalClassHierarchyMembers = @{}
            $this._mockedMethods = @{}
            $this._mockedProperties = @{}

            $theMockObject = New-PSObject
            Attach-PSNote $theMockObject '____mock____' $this

            # deal with class names, members from inheritance tree

            # attach base class names
            $classToAnalyze = $Class
            $i = 0
            while($classToAnalyze -ne $null) {
                foreach($key in $classToAnalyze.__Members.Keys) {
                    [Void]$this._originalClassHierarchyMembers.Add($key, $classToAnalyze.__Members[$key])
                }

                $theMockObject.psobject.TypeNames.Insert($i++, $classToAnalyze.__ClassName);
                $classToAnalyze = $classToAnalyze.__BaseClass
            }

            $mockDefinition = $this

            foreach($memberName in $this._originalClassHierarchyMembers.Keys) {
                $mockMemberInfo = New-PSClassInstance 'Aether.Class.Mock.MemberInfo'

                if($this._originalClassHierarchyMembers[$memberName] -is ([System.Management.Automation.PSScriptMethod])) {
                    $this._mockedMethods[$memberName] = $mockMemberInfo

                    Attach-PSScriptMethod $theMockObject $memberName $MockedMethodScriptBlock.GetNewClosure()
                }

                # PSPropertyInfo is the base class of noteProperties and scriptProperties
                if($this._originalClassHierarchyMembers[$memberName] -is ([System.Management.Automation.PSPropertyInfo])) {
                    $this._mockedProperties[$memberName] = $mockMemberInfo

                    $attachSplat = @{
                        InputObject = $theMockObject
                        Name = $memberName
                        Get = $MockedPropertyGetScriptBlock.GetNewClosure()
                        Set = $MockedPropertySetScriptBlock.GetNewClosure()
                    }

                    Attach-PSProperty @attachSplat
                }
            }

            $this.Object = $theMockObject
        }

        method '_GetMemberFromOriginal' {
            param (
                [string]$memberName
            )

            $member = $this._originalClassHierarchyMembers[$MemberName]
            if($member -eq $null) {
                $msg = "Member with name: '$MemberName' does not exist on this class/mock."
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
                AssertMemberType $member ([System.Management.Automation.PSScriptMethod])

                $setupInfo = New-PSClassInstance 'Aether.Class.Mock.MethodSetupInfo' -ArgumentList @(
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
                AssertMemberType $member ([System.Management.Automation.PSPropertyInfo])

                $setupInfo = New-PSClassInstance 'Aether.Class.Mock.PropertySetupInfo' -ArgumentList @(
                    $this,
                    $PropertyName,
                    $DefaultValue
                )

                $setups = $this._mockedProperties[$PropertyName].Setups

                if($setups.Count -gt 0) {
                    $setups[0] = $setupInfo
                } else {
                    [Void]$setups.Add($setupInfo)
                }

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

            # Rethrow resetting the call-stack so that
            # callers see the exception as happening at
            # this call site.
            # TODO: see how to mangle the stacktrace so
            # that the mock doesn't even show up there.
            try {
                Guard-ArgumentNotNull 'MethodName' $MethodName
                Guard-ArgumentNotNull 'Expressions' $Expressions
                Guard-ArgumentNotNull 'Times' $Times

                $member = $this._GetMemberFromOriginal($MethodName)
                AssertMemberType $member ([System.Management.Automation.PSMethodInfo])

                $Expectations = New-Object System.Collections.ArrayList
                foreach($expression in $Expressions) {
                    $msg = 'All objects in collection should be PSClass type Aether.Class.Mock.Expression'
                    Guard-ArgumentValid 'Expressions' $msg (ObjectIs-PSClassInstance $expression -PSClassName 'Aether.Class.Mock.Expression')
                    [Void]$Expectations.Add($expression.Predicate)
                }

                $callCount = 0
                foreach($call in $this._mockedMethods[$methodName].Calls) {
                    if($this._ArgumentsMeetExpectations($call.Arguments, $Expectations)) {
                        $callCount++
                    }
                }

                #ifdebug {
                #    'callCount: ' + $callCount
                #    'times: ' + $Times.ToString()
                #    'timesverify: ' + $Times.Verify($callCount)
                #}

                if(-not $Times.Verify($callCount)) {
                    $this._ThrowVerifyException($MethodName,
                        [InvocationType]::MethodCall,
                        $FailMessage,
                        $Expressions,
                        $this._mockedMethods[$MethodName].Setups,
                        $this._mockedMethods[$MethodName].Calls,
                        $Times,
                        $callCount)
                }
            } catch {
                throw $_.Exception.GetBaseException()
            }
        }

        method 'VerifyGet' {
            #[System.Diagnostics.DebuggerStepThrough()]
            param (
                [string]$PropertyName,
                [Times]$Times = [Times]::AtLeastOnce(),
                [string]$FailMessage
            )

            # Rethrow resetting the call-stack so that
            # callers see the exception as happening at
            # this call site.
            # TODO: see how to mangle the stacktrace so
            # that the mock doesn't even show up there.
            try {
                Guard-ArgumentNotNull 'PropertyName' $PropertyName
                Guard-ArgumentNotNull 'Times' $Times

                $member = $this._GetMemberFromOriginal($PropertyName)
                AssertMemberType $member ([System.Management.Automation.PSPropertyInfo])

                $callCount = $this._mockedProperties[$PropertyName].Calls.Count

                if(-not $Times.Verify($callCount)) {
                    $this._ThrowVerifyException($PropertyName,
                        [InvocationType]::PropertyGet,
                        $FailMessage,
                        @(),
                        $this._mockedProperties[$PropertyName].Setups,
                        $this._mockedProperties[$PropertyName].Calls,
                        $Times,
                        $callCount)
                }
            } catch {
                throw $_.Exception.GetBaseException()
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

            # Rethrow resetting the call-stack so that
            # callers see the exception as happening at
            # this call site.
            # TODO: see how to mangle the stacktrace so
            # that the mock doesn't even show up there.
            try {
                Guard-ArgumentNotNull 'PropertyName' $PropertyName
                $member = $this._GetMemberFromOriginal($PropertyName)
                AssertMemberType $member ([System.Management.Automation.PSPropertyInfo])

                if($Expression -ne $null) {
                    Guard-ArgumentIsPSClassInstance 'Expression' $Expression 'Aether.Class.Mock.Expression'
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
                    $this._ThrowVerifyException($PropertyName,
                        [InvocationType]::PropertySet,
                        $FailMessage,
                        @($Expression),
                        $this._mockedProperties[$PropertyName].Setups,
                        $this._mockedProperties[$PropertyName].Calls,
                        $Times,
                        $callCount)
                }
            } catch {
                throw $_.Exception.GetBaseException()
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

if(-not (Get-PSClass 'Aether.Class.Mock.MemberInfo')) {
    New-PSClass 'Aether.Class.Mock.MemberInfo' {
        note Setups
        note Calls

        constructor {
            $this.Setups = New-Object System.Collections.ArrayList
            $this.Calls = New-Object System.Collections.ArrayList
        }
    }
}

if(-not (Get-PSClass 'Aether.Class.Mock.SetupInfo')) {
    New-PSClass 'Aether.Class.Mock.SetupInfo' {
        note 'Mock'
        note 'Name'
        note 'Expressions'
        note 'Invocations'
        note 'InvocationType'
        note 'CallbackAction'
        note '_defaultReturnValue'
        note '_returnValueScript'
        property 'ReturnValue' -get {
            if($this._returnValueScript -ne $null) {
                return $this._returnValueScript.Invoke()
            } else {
                return $this._defaultReturnValue
            }
        } -set {
            param($value)
            $this._defaultReturnValue = $value
        }
        note 'CallCount'

        property 'Expectations' {
            $expectations = New-Object System.Collections.ArrayList
            foreach($expression in $this.Expressions) {
                [Void]$expectations.Add($expression.Predicate)
            }

            if($expectations.Count -le 1) {
                return ,$expectations
            }

            return $expectations
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

            if($Value -is [scriptblock]) {
                $this._returnValueScript = $Value
            } else {
                $this._defaultReturnValue = $Value
            }

            return $this
        }
    }
}

if(-not (Get-PSClass 'Aether.Class.Mock.PropertySetupInfo')) {
    New-PSClass 'Aether.Class.Mock.PropertySetupInfo' -Inherit 'Aether.Class.Mock.SetupInfo' {
        constructor {
            param (
                $Mock,
                $Name,
                $DefaultValue
            )

            Base $Mock $Name ([InvocationType]::PropertySet)

            [Void]$this.Expressions.Add((ItIs-Any ([object])))
            $this.ReturnValue = $DefaultValue
        }
    }
}

if(-not (Get-PSClass 'Aether.Class.Mock.MethodSetupInfo')) {
    New-PSClass 'Aether.Class.Mock.MethodSetupInfo' -Inherit 'Aether.Class.Mock.SetupInfo' {
        note 'ExceptionToThrow'

        constructor {
            param (
                $Mock,
                $Name,
                [System.Collections.IEnumerable]$Expressions = @()
            )

            Base $Mock $Name ([InvocationType]::MethodCall)

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

if(-not (Get-PSClass 'Aether.Class.Mock.CallContext')) {
    New-PSClass 'Aether.Class.Mock.CallContext' {
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

if(-not (Get-PSClass 'Aether.Class.Mock.Expression')) {
    New-PSClass 'Aether.Class.Mock.Expression' {
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

    return New-PSClassInstance 'Aether.Class.Mock' -ArgumentList @(
        $Class,
        $Strict
    )
}

$MockedMethodScriptBlock = {
    #because $this & $args are automatic variables,
    #the automatic version of the variable will
    #override the any variable with the same name that may be captured from GetNewClosure()
    $callContext = New-PSClassInstance 'Aether.Class.Mock.CallContext' -ArgumentList @(
        $mockDefinition,
        $memberName,
        ([InvocationType]::MethodCall),
        $args
    )

    [void]$mockDefinition._mockedMethods[$memberName].Calls.Add($callContext)

    $methodSetupInfo = $mockDefinition._GetMethodSetupInfoThatMeetExpectations($memberName, $args, $true)

    if($methodSetupInfo -eq $null) {
        if($Strict) {
            $msg = "This Mock is strict and no setups were configured for method {0}" -f $memberName
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
}

$MockedPropertyGetScriptBlock = {
    #because $this & $args are automatic variables,
    #the automatic version of the variable will
    #override the any variable with the same name that may be captured from GetNewClosure()
    $callContext = New-PSClassInstance 'Aether.Class.Mock.CallContext' -ArgumentList @(
        $mockDefinition,
        $memberName,
        [InvocationType]::PropertyGet
    )

    [void]$mockDefinition._mockedProperties[$memberName].Calls.Add($callContext)

    $setups = $mockDefinition._mockedProperties[$memberName].Setups

    if($setups.Count -gt 0) {
        return $setups[0].ReturnValue
    }
}

$MockedPropertySetScriptBlock = {
    #because $this & $args are automatic variables,
    #the automatic version of the variable will
    #override the any variable with the same name that may be captured from GetNewClosure()
    $callContext = New-PSClassInstance 'Aether.Class.Mock.CallContext' -ArgumentList @(
        $mockDefinition,
        $memberName,
        [InvocationType]::PropertySet,
        $Args[0]
    )

    [void]$mockDefinition._mockedProperties[$memberName].Calls.Add($callContext)

    if($Strict -and $mockDefinition._mockedProperties[$memberName].Setups.Count -eq 0) {
        $msg = "This Mock is strict and no setups were configured for setter of property $memberName"
        throw (new-object PSMockException([ExceptionReason]::MockConsistencyCheckFailed, $msg))
    }
}