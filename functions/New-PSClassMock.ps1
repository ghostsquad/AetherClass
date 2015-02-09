if(-not Get-PSClass 'GpClass.Mock') {
    New-PSClass 'GpClass.Mock' {
        note '_strict' ([bool]$Strict)
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
            Attach-PSNote $theMockObject '____mock' $this

            $mockDefinition = $this

            foreach($methodName in $Class.__Methods.Keys) {
                $this._mockedMethods[$methodName] = New-Object System.Collections.Arraylist
                $mockedMethodScript = {
                    #because $this & $args are automatic variables,
                    #the automatic version of the variable will
                    #override the any variable with the same name that may be captured from GetNewClosure()
                    $methodSetupInfoCollection = $mockDefinition._mockedMethods[$methodName]
                    foreach($methodSetupInfo in $mockDefinition._mockedMethods[$methodName]) {
                        $invocationMetExpections = $true
                        if($methodSetupInfo.Expectations.Count -ne $Args.Count) {
                            $invocationMetExpections = $false
                        }

                        for($i = 0; -lt $Args.Count; $i++) {
                            $invocationMetExpections = $methodSetupInfo.Expectations[$i].Invoke($Args[$i])
                            if(-not $invocationMetExpections) {
                                break;
                            }
                        }

                        if($invocationMetExpections) {
                            [Void]$methodSetupInfo.Invocations.Add($Args)
                            if($methodSetupInfo.ExceptionToThrow -ne $null) {
                                throw $methodSetupInfo.ExceptionToThrow
                            }

                            [Void]$methodSetupInfo.InvokeMethodScript($Args)
                            [Void]$methodSetupInfo.CallBackAction.Invoke($Args)
                            return $methodSetupInfo.ReturnValue
                        }
                    }

                    if($Strict) {
                        throw (new-object PSMockException("This Mock is strict and no expectation was set for method ...."))
                    }
                }.GetNewClosure()

                Attach-PSScriptMethod $theMockObject $methodName $mockedMethodScript
            }

            $notesAndPropertyKeys = New-Object System.Collections.Arraylist
            $notesAndPropertyKeys.AddRange($Class.__Properties.Keys)
            $notesAndPropertyKeys.AddRange($Class.__Notes.Keys)

            foreach($propertyName in $notesAndPropertyKeys) {
                $this._mockedProperties[$propertyName] = New-Object System.Collections.Arraylist
                Attach-PSProperty $theMockObject $propertyName {} {}
            }

            $this.Object = $theMockObject
        }

        method 'Setup' {
            param (
                [string]$MethodName,
                [func[object, bool][]]$Expectations = (New-Object 'func[object, bool][]'(0))
            )

            Guard-ArgumentNotNull 'MethodName' $MethodName
            Guard-ArgumentNotNull 'Expectations' $Expectations

            if(-not $this._originalClass.__Methods.ContainsKey($MethodName)) {
                throw (new-object PSMockException("Method with name: $MethodName cannot be found to mock!"))
            }

            $mockMethodInfo = New-PSClassInstance 'PSClass.MockMethodInfo' -ArgumentList @(
                $this,
                $MethodName
            )

            return $mockMethodInfo
        }

        method 'Verify' {
            param (
                [string]$MethodName
              , [func[object, bool][]]$Expectations = (New-Object 'func[object, bool][]'(0))
              , [Times]$Times = [Times]::AtLeastOnce()
            )

            Guard-ArgumentNotNull 'MethodName' $MethodName
            Guard-ArgumentNotNull 'Expectations' $Expectations
            Guard-ArgumentNotNull 'Times' $Times

            $callCountThatMetExpectations = 0;
            $mockedMethod = $this._mockedMethods[$MethodName]
            if($mockedMethod -eq $null) {
                throw (new-object PSMockException(
                    [string]::Format("Unable to verify a method [{0}] that has no expectations!",
                        $MethodName)))
            }

            foreach($invocationArgsCollection in $mockedMethod.Invocations) {
                $invocationMetExpections = $true
                if($Expectations.Count -ne $invocationArgsCollection.Count) {
                    $invocationMetExpections = $false
                }
                for($i = 0; -lt $invocationArgsCollection.Count; $i++) {
                    $invocationMetExpections = $Expectations[$i].Invoke($invocationArgsCollection[$i])
                    if(-not $invocationMetExpections) {
                        break;
                    }
                }

                if($invocationMetExpections) {
                    $callCountThatMetExpectations++
                }
            }

            if(-not $Times.Verify($callCountThatMetExpectations)) {
                #TODO
                $msg = $Times.GetExceptionMessage()
                throw $msg
            }
        }

        method 'VerifyGet' {
            param (
                [string]$MemberName
              , [Times]$Times = [Times]::AtLeastOnce()
            )

            Guard-ArgumentNotNull 'MemberName' $MemberName
            Guard-ArgumentNotNull 'Times' $Times

            #TODO
        }

        method 'VerifySet' {
            param (
                [string]$MemberName,
              , [func[object, bool]]$Expectation,
              , [Times]$Times = [Times]::AtLeastOnce()
            )

            Guard-ArgumentNotNull 'MemberName' $MemberName
            Guard-ArgumentNotNull 'Expectation' $Expectation
            Guard-ArgumentNotNull 'Times' $Times

            #TODO
        }
    }
}

if(-not (Get-PSClass 'PSClass.Mock.MethodSetupInfo')) {
    New-PSClass 'PSClass.Mock.MethodSetupInfo' {
        note 'Mock'
        note 'Name'
        note 'SetupScript'
        note 'Expectations'
        note 'Invocations'
        note 'CallbackScript'
        note 'ReturnValue'
        note 'ExceptionToThrow'

        constructor {
            param (
                $Mock,
                $Name,
                $SetupScript = {},
                [func[object, bool][]]$Expectations = (New-Object 'func[object, bool][]'(0))
            )

            $this.Mock = $Mock
            $this.Name = $Name
            $this.SetupScript = $SetupScript
            $this.Expections = $Expectations
            $this.ReturnValue = $null
            $this.ExceptionToThrow = $null
            [Action]$this.CallbackAction = {}
            $this.Invocations = (New-Object System.Collections.ArrayList)
        }

        method 'InvokeMethodScript' {
            param($theArgs)

            [void]$this.Invocations.Add($theArgs)

            $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10 = $theArgs
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
                    throw (new-object PSMockException("PSClassMock does not support more than 10 arguments for a method mock."))
                }
            }
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