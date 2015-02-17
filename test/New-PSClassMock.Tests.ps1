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

            $setupInfo = $mock.Setup('foo', {return $true})

            $setupInfo.Expectations.Count | Should Be 1
            $setupInfo.Expectations[0].Invoke('anyvalue') | Should Be $true
        }

        It 'Method Setup - with no expectations and no args, when verify, expect no exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo')
            $mock.Object.foo()

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Setup - with no expectations and one arg, when verify, expect no exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo')
            $mock.Object.foo()

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Setup - with fewer expectations than args, when verify, expect no exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo', @((ItIs-Any ([object]))))

            # this call should be recorded, verification should not throw
            # because we've created a setup that expects at least one arg of type [object]
            $mock.Object.foo(1,2)

            { $mock.Verify('foo') } | Should Not Throw
        }

        It 'Method Setup - with fewer expectations than args, and mismatch, when verify, expect exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo', @((ItIs-Any ([string]))))

            # this call should be recorded, verification should not throw
            # because we've created a setup that expects at least one arg of type [object]
            $mock.Object.foo(1,2)

            $expectedMessage = 'Expected invocation on the mock at least once, but was never performed: foo()'
            { $mock.Verify('foo') } | Should Throw $expectedMessage
        }

        It 'Method Setup - with more expectations than args, when verify, expect exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo', @((ItIs-Any ([object]))))

            # this call should be recorded, verification should throw
            # because we've created a setup that expects at least one arg of type [object]
            $mock.Object.foo()

            $expectedMessage = 'Expected invocation on the mock at least once, but was never performed: foo()'
            { $mock.Verify('foo') } | Should Throw $expectedMessage
        }

        It 'Method Setup - with mismatched expectations and args, when verify, expect exception' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $setupInfo = $mock.Setup('foo', @((ItIs-Any ([string]))))

            # this call should be recorded, verification should throw
            # because we've created a setup that expects at least one arg of type [object]
            $mock.Object.foo(1)

            { $mock.Verify('foo') } | Should Throw 'asdf'
        }
    }

    Context 'Rainy' {
        It 'Method Setup - Throws if method does not exist' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            $mock = New-PSClassMock $testClass

            { $mock.Setup('foo') } | Should Throw 'asdf'
        }

        It 'Method Setup - Can Set Return Value After Setup' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $expectedReturnValue = [Guid]::NewGuid()
            $setupInfo = $mock.Setup('foo').Returns($expectedReturnValue)

            $mock.Object.foo() | Should Be $expectedReturnValue
        }

        It 'Method Setup - Can Set Method to Throw an Exception After Setup' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method 'foo' {}
            } -PassThru
            $mock = New-PSClassMock $testClass

            $expectedException = New-Object Exception('my exception')
            $setupInfo = $mock.Setup('foo').Throws($expectedException)

            try {
                $mock.Object.foo()
            } catch {
                $actualException = $_
            }

            $actualException -eq $null | Should Be $false
            [object]::ReferenceEquals($actualException, $expectedException) | Should Be $true
        }
    }
}

Describe 'PSClass.Mock.MethodSetupInfo' {
    Context 'Sunny' {
        It 'Sets Name Note from constructor' {
            $instance = New-PSClassInstance 'PSClass.Mock.MethodSetupInfo' -ArgumentList @(
                'foo'
            )

            $instance.Name | Should Be 'foo'
        }

        It 'Sets adds expectations from constructor' {
            $instance = New-PSClassInstance 'PSClass.Mock.MethodSetupInfo' -ArgumentList @(
                'foo',
                @({return $true})
            )

            $instance.Expectations.Count | Should Be 1
            $instance.Expectations[0].Invoke('anyvalue') | Should Be $true
        }
    }

    Context 'Rainy' {

    }
}