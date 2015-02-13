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
            $mock._mockedMethods['foo'].GetType() | Should Be ([System.Collections.ArrayList])
            $mock._mockedMethods['foo'].Count | Should Be 0
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
    }

    Context 'Rainy' {
        It 'Method Setup - Throws if method does not exist' {

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