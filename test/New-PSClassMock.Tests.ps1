$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\TestCommon.ps1"

Describe "New-PSClassMock" {
    Context 'Sunny' {
        It 'Mock Creation - Can use PSClass name' {
            $className = [Guid]::NewGuid().ToString()
            New-PSClass $className {}

            { New-PSClassMock $className } | Should Not Throw
        }

        It 'Mock Creation - Can use PSClass definition object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            { New-PSClassMock $testClass } | Should Not Throw
        }

        It 'Mock Creation - Methods have no SetupInfos by default' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock._mockedMethods.ContainsKey('foo') | Should Be $true
            $mock._mockedMethods['foo'].Setups.Count | Should Be 0
        }

        #region Method Setup

        It 'Method Setup - Returns MethodSetupInfo Object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass
            $actual = $mock.Setup('foo')
            { ObjectIs-PSClassInstance $actual 'GpClass.SetupInfo' } | Should Be $true
            { ObjectIs-PSClassInstance $actual 'GpClass.MethodSetupInfo' } | Should Be $true
        }

        It 'Method Setup - MethodSetupInfo has MethodName' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo')

            $setupInfo.Name | Should Be 'foo'
        }

        It 'Method Setup - Given no expectations, MethodSetupInfo has no expectations' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo')

            $setupInfo.Expectations.Count | Should Be 0
        }

        It 'Method Setup - Given an expectation, MethodSetupInfo retains expectation' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo', @(ItIs-Any([object])))

            $setupInfo.Expectations.Count | Should Be 1
            $setupInfo.Expectations[0].Invoke('anyvalue') | Should Be $true
        }

        It 'Method Setup - No Expectations, No Return Value, When Called, Returns Null' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Setup('foo')

            [object]$actualValue = $mock.Object.foo('anyvalue')
            $actualValue -eq $null | Should Be $true
        }

        It 'Method Setup - No Setup and Strict, When Called, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass -Strict

            $expectedMessage = 'Exception calling "foo" with "1" argument(s): "This Mock is strict and no setups were configured for method foo"'
            { $mock.Object.foo('anyvalue') } | Should Throw $expectedMessage
        }

        It 'Method Setup - No Expectations, When Called, Returns Provided Return Value' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Setup('foo').Returns('expected')

            [object]$actualValue = $mock.Object.foo()

            $actualValue | Should Be 'expected'
        }

        It 'Method Setup - Single Expectation, Called With 1 Arg, Returns Provided Return Value' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Setup('foo', @(ItIs-Any([string]))).Returns('expected')

            $actualValue = $mock.Object.foo('anyvalue')

            $actualValue | Should Be 'expected'
        }

        It 'Method Setup - Fewer Expectations than Args, Returns Provided Return Value' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass
            $mock.Setup('foo', @(ItIs-Any([string]))).Returns('expected')

            $actualValue = $mock.Object.foo('anyvalue', 'anothervalue')

            $actualValue | Should Be 'expected'
        }

        It 'Method Setup - More Expectations than Args, Expect Return $null (default)' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass
            $mock.Setup('foo', @((ItIs-Any ([string])), (ItIs-Any([string])))).Returns('expected')

            $actualValue = $mock.Object.foo('anyvalue')
            $actualValue -eq $null | Should Be $true
        }

        It 'Method Setup - Multiple Setups - When both Setups can Match, Expect First Setup Matched' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass
            $mock.Setup('foo', @(ItIs-Any([string]))).Returns('expected')
            $mock.Setup('foo', @(ItIs-Any([string]))).Returns('notexpected')

            $actualValue = $mock.Object.foo('anyvalue')
            $actualValue | Should Be 'expected'
        }

        It 'Method Setup - Multiple Setups - When Second Setup Matches, Expect Second Setup Matched' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass
            $mock.Setup('foo', @(ItIs-Any([int]))).Returns('notexpected')
            $mock.Setup('foo', @(ItIs-Any([string]))).Returns('expected')

            $actualValue = $mock.Object.foo('anyvalue')
            $actualValue | Should Be 'expected'
        }

        It 'Method Setup - Multiple Setups - When neither setup matches, Expect return $null (default)' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass
            $mock.Setup('foo', @(ItIs-Any([int]))).Returns('notexpected1')
            $mock.Setup('foo', @(ItIs-Any([bool]))).Returns('notexpected2')

            $actualValue = $mock.Object.foo('anyvalue')
            $actualValue -eq $null | Should Be $true
        }

        It 'Method Setup - Expected Throw - Can Set Method to Throw an Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $expectedException = New-Object Exception('my exception')
            $setupInfo = $mock.Setup('foo').Throws($expectedException)

            try {
                $mock.Object.foo()
            } catch {
                $actualException = $_.Exception
            }

            $actualException -eq $null | Should Be $false
            $actualException.Message | Should Be 'Exception calling "foo" with "0" argument(s): "my exception"'
            [object]::Equals($actualException.GetBaseException(), $expectedException) | Should Be $true
        }

        It 'Method Setup - Returns - Given ScriptBlock, evaluates scriptblock lazily' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $i = 0
            $setupInfo = $mock.Setup('foo').Returns({ return $script:i += 1; }.GetNewClosure())

            $mock.Object.foo() | Should Be 1
            $mock.Object.foo() | Should Be 2
        }

        #endregion Method Setup

        #region Method Verify

        It 'Method Verify - Setup Not Required To Verify Call was Made' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Object.foo()

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Verify - Setup Differs From Call, Verification Still Successful' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Setup('foo', @(ItIs-Any([int])))

            $mock.Object.foo()

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Verify - No Expectations - Called with One Arg, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo')

            $mock.Object.foo(1)

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Verify - 1 Expectation - Called with No Args, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Object.foo()

            $expectedMessage = 'Exception calling "Verify" with "2" argument(s): "' `
                + [Environment]::NewLine `
                + 'Expected invocation on the mock at least once, but was never performed: foo(ItIs-Any{Type=string})' `
                + [Environment]::NewLine `
                + 'No setups configured.' `
                + [Environment]::NewLine `
                + [Environment]::NewLine `
                + 'Performed invocations:' `
                + [Environment]::NewLine `
                + $className + '.foo()"'

            { $mock.Verify('foo', @(ItIs-Any([string]))) } | Should Throw $expectedMessage
        }

        It 'Method Verify - Expectation does not match args, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Object.foo(1)

            $expectedMessage = 'Exception calling "Verify" with "2" argument(s): "' `
                + [Environment]::NewLine `
                + 'Expected invocation on the mock at least once, but was never performed: foo(ItIs-Any{Type=string})' `
                + [Environment]::NewLine `
                + 'No setups configured.' `
                + [Environment]::NewLine `
                + [Environment]::NewLine `
                + 'Performed invocations:' `
                + [Environment]::NewLine `
                + $className + '.foo(1)"'

            { $mock.Verify('foo', @(ItIs-Any([string]))) } | Should Throw $expectedMessage
        }

        It 'Method Verify - Many Expectations - Called with Many Args, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Object.foo(1, 'foo')

            $expectation1 = ItIs-Any ([int])
            $expectation2 = ItIs-Any ([string])
            { $mock.Verify('foo', @($expectation1, $expectation2)) } | Should Not Throw
        }

        #endregion Method Verify

        #region Property Setup
        It 'Property Setup - Can Setup Property Get' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.SetupProperty('foo', 'expected')

            $mock.Object.Foo | Should Be 'expected'
        }

        It 'Property Setup - Can Setup Note Get' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'foo'
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.SetupProperty('foo', 'expected')

            $mock.Object.Foo | Should Be 'expected'
        }

        It 'Property Setup - Can Setup Return Value using Fluent API' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.SetupProperty('foo').Returns('expected')

            $mock.Object.Foo | Should Be 'expected'
        }

        It 'Property Setup - Without Setup, Property returns $null (default)' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $mock.Object.Foo -eq $null | Should Be $true
        }

        It 'Property Setup - Without Setup, and Strict, When Set, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass -Strict

            $expectedMessage = 'Exception setting "foo": "This Mock is strict and no setups were configured for setter of property foo"'
            { $mock.Object.Foo = 'bar' } | Should Throw $expectedMessage
        }

        It 'Property Setup - When setup multiple times, expect last setup to apply' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupProperty('foo').Returns('default_setup')
            $mock.SetupProperty('foo').Returns('expectedvalue')

            $mock.Object.foo | Should Be 'expectedvalue'
        }

        It 'Property Setup - When setup after default value is established, expect last setup to apply' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupProperty('foo', 'default_setup')
            $mock.SetupProperty('foo').Returns('expectedvalue')

            $mock.Object.foo | Should Be 'expectedvalue'
        }

        #endregion Property Setup

        #region Property Get Verify

        It 'Property Get Verify - No Setup, When Called, When Verify, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $actual = $mock.Object.Foo

            # assert
            { $mock.VerifyGet('Foo') } | Should Not Throw
        }

        It 'Property Get Verify - When Setup, When Called When Verify, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $mock.SetupProperty('foo').Returns('bar')
            $actual = $mock.Object.Foo

            # assert
            { $mock.VerifyGet('Foo') } | Should Not Throw
        }

        It 'Property Get Verify - When Get Not Called, When Verify, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $expectedMessage = 'Exception calling "VerifyGet" with "1" argument(s): "' `
                + [Environment]::NewLine `
                + 'Expected invocation on the mock at least once, but was never performed: Foo' `
                + [Environment]::NewLine `
                + 'No setups configured.' `
                + [Environment]::NewLine `
                + 'No invocations performed."'

            { $mock.VerifyGet('Foo') } | Should Throw $expectedMessage
        }

        #endregion Property Get Verify

        #region Property Set Verify

        It 'Property Set Verify - When Called, When Verify, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $mock.Object.Foo = 'bar'

            # assert
            { $mock.VerifySet('Foo', (ItIs-Any ([object]))) } | Should Not Throw
        }

        It 'Property Set Verify - When Called, When Verify with MisMatched Expectation, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $mock.Object.Foo = 'bar'

            $expectedMessage = 'Exception calling "VerifySet" with "2" argument(s): "' `
                + [Environment]::NewLine `
                + 'Expected invocation on the mock at least once, but was never performed: Foo = ItIs-Any{Type=int}' `
                + [Environment]::NewLine `
                + 'No setups configured.' `
                + [Environment]::NewLine `
                + [Environment]::NewLine `
                + 'Performed invocations:' `
                + [Environment]::NewLine `
                + $className + '.foo = bar"'

            { $mock.VerifySet('Foo', (ItIs-Any ([int]))) } | Should Throw $expectedMessage
        }

        It 'Property Set Verify - When Called Multiple Times, When Second Set Matches Verify, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $mock.Object.Foo = 'bar'
            $mock.Object.Foo = 1

            # assert
            { $mock.VerifySet('Foo', (ItIs-Any ([int]))) } | Should Not Throw
        }

        It 'Property Set Verify - When Setup, When Verify, Expect No Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            # act
            $mock.SetupProperty('foo').Returns('bar')
            $mock.Object.Foo = 'newbar'

            # assert
            { $mock.VerifySet('foo', (ItIs-Any ([object]))) } | Should Not Throw
        }

        It 'Property Set Verify - When Set Not Called, When Verify, Expect Exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' { return 'unexpected' }
            } -PassThru
            $mock = New-PSClassMock $testClass

            $expectedMessage = 'Exception calling "VerifySet" with "2" argument(s): "' `
                + [Environment]::NewLine `
                + 'Expected invocation on the mock at least once, but was never performed: Foo = ItIs-Any{Type=System.Object}' `
                + [Environment]::NewLine `
                + 'No setups configured.' `
                + [Environment]::NewLine `
                + 'No invocations performed."'

            { $mock.VerifySet('Foo', (ItIs-Any ([object]))) } | Should Throw $expectedMessage
        }

        #endregion Property Set Verify
    }

    Context 'Rainy' {
        It 'Method Setup - Throws if method does not exist' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            $mock = New-PSClassMock $testClass

            $expectedMessage = 'Exception calling "SetupProperty" with "1" argument(s): "Member with name: foo cannot be found to mock!"'

            { $mock.SetupProperty('foo') } | Should Throw $expectedMessage
        }
    }
}