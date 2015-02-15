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
                $this._mockedMethods[$methodName] = New-PSClassInstance 'PSClass.Mock.MemberInfo'

                $mockedMethodScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $callContext = New-PSClassInstance 'GpClass.Mock.CallContext' -ArgumentList @(
                        [InvocationType]::MethodCall,
                        $Args
                    )

                    $this.____mock____._mockedMethods[$methodName].Calls.Add($callContext)
                    $methodSetupInfo = $this.____mock____._GetMethodSetupInfosThatMetExpectations($true)
                    if($methodSetupInfo -ne $null) {
                        $callContext.SetupInfo = $methodSetupInfo
                        [Void]$methodSetupInfo.Invocations.Add($callContext)
                        if($methodSetupInfo.ExceptionToThrow -ne $null) {
                            throw $methodSetupInfo.ExceptionToThrow
                        }

                        [Void]$methodSetupInfo.InvokeMethodScript($Args)
                        [Void]$methodSetupInfo.CallBackAction.Invoke($Args)
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
                $this._mockedProperties[$propertyName] = New-PSClassInstance 'PSClass.Mock.MemberInfo'

                $mockedPropertyGetScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $callContext = New-PSClassInstance 'GpClass.Mock.CallContext' -ArgumentList @(
                        [InvocationType]::PropertyGet
                    )
                    $this.____mock____._mockedProperties[$propertyName].Calls.Add($callContext)

                    $propertySetupInfoCollection = $mockDefinition._mockedProperties[$propertyName].Setups
                    $condition = {ObjectIs-PSClassInstance $_ 'PSClass.Mock.PropertySetupInfo'}
                    if(Where-Any -InputObject $propertySetupInfoCollection -Condition $condition) {
                        $callContext.SetupInfo = $propertySetupInfoCollection[0]
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
                        [InvocationType]::PropertySet,
                        $Args[0]
                    )
                    $this.____mock____._mockedProperties[$propertyName].Calls.Add($callContext)

                    $propertySetupInfoCollection = $mockDefinition._mockedProperties[$propertyName].Setups
                    $condition = {ObjectIs-PSClassInstance $_ 'PSClass.Mock.PropertySetupInfo'}
                    if(Where-Any -InputObject $propertySetupInfoCollection -Condition $condition) {
                        $callContext.SetupInfo = $propertySetupInfoCollection[0]
                        [Void]$propertySetupInfo.Invocations.Add($callContext)
                        return $propertySetupInfo.ReturnValue
                    }

                    if($Strict) {
                        $msg = "This Mock is strict and no expectation was set for property $propertyName"
                        throw (new-object PSMockException($msg))
                    }
                }.GetNewClosure()

                #Attach-PSProperty $theMockObject $propertyName $mockedPropertyGetScript $mockedPropertySetScript
                Attach-PSProperty $theMockObject $propertyName {} {}
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

            $setupInfo = New-PSClassInstance 'PSClass.Mock.MethodSetupInfo' -ArgumentList @(
                $MethodName,
                $Expectations
            )

            [Void]$this._mockedMethods[$MethodName].Add($setupInfo)

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

            $setupInfo = New-PSClassInstance 'PSClass.Mock.PropertySetupInfo' -ArgumentList @(
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

            $callCount = ($this._GetMethodSetupInfosThatMetExpectations($false)).Count

            if(-not $Times.Verify($callCountThatMetExpectations)) {
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
                [func[object, bool][]]$Expectations = (New-Object 'func[object, bool][]'(0)),
                [Ienumerable[psobject]]$Setups,
                [Ienumerable[psobject]]$ActualCalls,
                [Times]$Times,
                [int]$CallCount
            )

            $Expression = $MemberName + "(" + $this._ConvertExpectationsToExpressionString($Expectations) + ")"

            [string]$msg = $Times.GetExceptionMessage($FailMessage, $Expression, $CallCount) + `
                [environment]::NewLine + $this._FormatSetupsInfo($Setups) + `
                [environment]::NewLine + $this._FormatInvocations($ActualCalls)

            throw (New-Object PSMockException([ExceptionReason]::VerificationFailed, $msg))
        }

        method '_FormatSetupsInfo' {
            param (
                [Ienumerable[psobject]]$Setups
            )
            #var expressionSetups = setups
            #    .Select(s => s.SetupExpression.ToStringFixed() + ", " + FormatCallCount(s.CallCount))
            #    .ToArray();

            #return expressionSetups.Length == 0 ?
            #    "No setups configured." :
            #    Environment.NewLine + "Configured setups:" + Environment.NewLine + string.Join(Environment.NewLine, expressionSetups);
        }

        method '_FormatCallCount' {
            param (
                [int]$CallCount
            )
            #if (callCount == 0)
            #{
            #    return "Times.Never";
            #}

            #if (callCount == 1)
            #{
            #    return "Times.Once";
            #}

            #return string.Format(CultureInfo.CurrentCulture, "Times.Exactly({0})", callCount);
        }

        method '_FormatInvocations' {
            param (
                [Ienumerable[psobject]]$Invocations
            )
            #var formattedInvocations = invocations
            #    .Select(i => i.Format())
            #    .ToArray();

            #return formattedInvocations.Length == 0 ?
            #    "No invocations performed." :
            #    Environment.NewLine + "Performed invocations:" + Environment.NewLine + string.Join(Environment.NewLine, formattedInvocations);
        }

        method '_ConvertExpectationsToExpressionString' {
            [cmdletbinding()]
            param (
                [func[object, bool][]]$Expectations = @()
            )

            $FuncStrings = @()
            foreach($expectation in $Expectations) {
                $FuncStrings += $expectation.Target.Constants[0].ToString().Trim("`n").Trim()
            }

            return [string]::Join($FuncStrings, ", ")
        }

        method '_GetMethodSetupInfosThatMetExpectations' {
            param (
                $StopOnFirst = $false
            )

            $MetExpectationsSetupInfoCollection = @()

            $methodSetupInfoCollection = $this._mockedMethods[$methodName].Setups
            foreach($methodSetupInfo in $methodSetupInfoCollection) {
                $invocationMetExpections = $false

                if($methodSetupInfo.Expectations.Count -eq $Args.Count) {
                    for($i = 0; $i -lt $Args.Count; $i++) {
                        $invocationMetExpections = $methodSetupInfo.Expectations[$i].Invoke($Args[$i])
                        if(-not $invocationMetExpections) {
                            break;
                        }
                    }
                }

                if($StopOnFirst) {
                    return $methodSetupInfo
                }

                $MetExpectationsSetupInfoCollection += $methodSetupInfo
            }

            if($MetExpectationsSetupInfoCollection.Count -gt 1) {
                return $MetExpectationsSetupInfoCollection
            }

            return ,$MetExpectationsSetupInfoCollection
        }
    }
}

if(-not (Get-PSClass 'PSClass.Mock.MemberInfo')) {
    New-PSClass 'PSClass.Mock.MemberInfo' {
        note Setups
        note Calls

        constructor {
            $this.Setups = New-Object System.Collections.ArrayList
            $this.Calls = New-Object System.Collections.ArrayList
        }
    }
}

if(-not (Get-PSClass 'PSClass.Mock.SetupInfo')) {
    New-PSClass 'PSClass.Mock.SetupInfo' {
        note 'Name'
        note 'Mock'
        note 'Expectations'
        note 'Invocations'
        note 'CallbackAction'
        note 'ReturnValue'

        constructor {
            param (
                $Name
            )

            $this.Name = $Name
            $this.Expectations = New-Object 'System.Collections.Generic.List[func[object, bool]]'
            [Action]$this.CallbackAction = {}
            $this.Invocations = New-Object System.Collections.ArrayList
            $this.ReturnValue = $null
        }

        method 'CallBack' {
            param (
                [Action]$Action
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

if(-not (Get-PSClass 'PSClass.Mock.PropertySetupInfo')) {
    New-PSClass 'PSClass.Mock.PropertySetupInfo' -Inherit 'PSClass.Mock.SetupInfo' {
        constructor {
            param (
                $Name,
                $DefaultValue
            )

            Base $Name

            [Void]$this.Expectations.Add((ItIs-Any ([object])))
            $this.ReturnValue = $DefaultValue
        }
    }
}

if(-not (Get-PSClass 'PSClass.Mock.MethodSetupInfo')) {
    New-PSClass 'PSClass.Mock.MethodSetupInfo' -Inherit 'PSClass.Mock.SetupInfo' {
        note 'ExceptionToThrow'

        constructor {
            param (
                $Name,
                [func[object, bool][]]$Expectations = @()
            )

            Base $Name

            [Void]$this.Expectations.AddRange($Expectations)
            $this.ExceptionToThrow = $null
        }

        method 'InvokeMethodScript' {
            param($theArgs)

            $private:p1, $private:p2, $private:p3, $private:p4, $private:p5, $private:p6, `
                $private:p7, $private:p8, $private:p9, $private:p10 = $theArgs
            switch($theArgs.Count) {
                0 {  return $this.SetupScript.InvokeReturnAsIs() }
                1 {  return $this.SetupScript.InvokeReturnAsIs($p1) }
                2 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2) }
                3 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3) }
                4 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4) }
                5 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5) }
                6 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6) }
                7 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7) }
                8 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) }
                9 {  return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9) }
                10 { return $this.SetupScript.InvokeReturnAsIs($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10) }
                default {
                    $msg = "PSClassMock does not support more than 10 arguments for a method mock."
                    throw (new-object PSMockException($msg))
                }
            }
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

if(-not (Get-PSClass 'PSClass.Mock.CallContext')) {
    New-PSClass 'PSClass.Mock.CallContext' {
        note InvocationType
        note Arguments
        note SetupInfo

        constructor {
            param (
                [InvocationType]$InvocationType,
                [object[]]$Arguments = @()
            )

            $this.InvocationType = $InvocationType
            $this.Arguments = $Arguments
        }

        method 'Format' {
            if ($this.InvocationType -eq [InvocationType]::PropertyGet) {
                return $this.SetupInfo.Mock._originalClass.__ClassName + "." + $this.SetupInfo.Name;
            }

            if ($this.InvocationType -eq [InvocationType]::PropertySet)
            {
                return $this.SetupInfo.Mock._originalClass.__ClassName + "." +
                    $this.SetupInfo.Name + " = " + $this.Arguments[0]
            }

            return $this.SetupInfo.Mock._originalClass.__ClassName + "." + $this.SetupInfo.Name; + "(" +
                [string]::Join(", ", $this.Arguments) + ")";
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