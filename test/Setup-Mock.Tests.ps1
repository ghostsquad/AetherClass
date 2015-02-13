$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\TestCommon.ps1"

Describe 'Setup-Mock' {
    Context 'Method - Sunny Day' {
        BeforeEach {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    throw "not implemented"
                }
            } -PassThru
        }

        It 'Given -PassThru, Pipeline & -Mock, produce the same object' {
            $mock = New-PSClassMock $testClass
            $pipelineActual = $mock | Setup-Mock -Method 'foo' -PassThru
            $mockParamActual = Setup-Mock -Mock $mock -Method 'foo' -PassThru

            { $pipelineActual -ne $null } | Should Be $true
            { $pipelineActual.Equals($mockParamActual) } | Should Be $true
        }

        It 'Given Mock from Pipeline & PassThru, returns SetupInfo PSClass Instance' {
            $mock = New-PSClassMock $testClass
            $actual = $mock | Setup-Mock -Method 'foo' -PassThru
            { ObjectIs-PSClassInstance $actual 'GpClass.SetupInfo' } | Should Be $true
        }

        It 'Mock has SetupInfo created by Setup-Mock' {
            $mock = New-PSClassMock $testClass
            $actualSetupInfo = $mock | Setup-Mock -Method 'foo' -PassThru
            $mock._mockedMethods['foo'].Count | Should Be 1
            $mock._mockedMethods['foo'][0] | Should Be $actualSetupInfo
        }

        It 'Passes expectations to SetupInfo object' {
            $mock = New-PSClassMock $testClass
            $actualSetupInfo = $mock | Setup-Mock -Method 'foo' -Expectations {param($a) return $true} -PassThru
            $actualSetupInfo.Expectations.Count | Should Be 1
            $actualSetupInfo.Expectations[0].Invoke('anyvalue') | Should Be $true
        }
    }

    Context 'Method - Rainy Day' {
        BeforeEach {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    throw "not implemented"
                }

                note "imanote"
                property 'iamaproperty' {}
            } -PassThru
        }

        It 'Throws when -Mock is not a GpClass.Mock Instance' {
            $msg = 'InputObject does not appear have been created by New-PSClass.' -f $className
            { New-PSObject | Setup-Mock -Method 'foo' } | Should Throw $msg
        }

        It 'Throws when -Method parameter does not exist' {
            $mock = New-PSClassMock $testClass
            $msg = "Member with name: bar cannot be found to mock!"
            { $mock | Setup-Mock -Method 'bar' } | Should Throw $msg
        }

        It 'Throws when -Method parameter maps to note instead of method' {
            $mock = New-PSClassMock $testClass
            $msg = "Member imanote is not a PSScriptMethod."
            { $mock | Setup-Mock -Method 'imanote' } | Should Throw $msg
        }

        It 'Throws when -Method parameter maps to property instead of method' {
            $mock = New-PSClassMock $testClass
            $msg = "Member iamaproperty is not a PSScriptMethod."
            { $mock | Setup-Mock -Method 'iamaproperty' } | Should Throw $msg
        }

        It 'Throws if methodname is null' {
            $mock = New-PSClassMock $testClass
            $msg = "Argument was empty."
            $msg += "`r`nParameter name: MethodName"
            { $mock | Setup-Mock -Method $null -Expectations $null } | Should Throw $msg
        }

        It 'Throws if methodname is empty' {
            $mock = New-PSClassMock $testClass
            $msg = "Argument was empty."
            $msg += "`r`nParameter name: MethodName"
            { $mock | Setup-Mock -Method '' -Expectations $null } | Should Throw $msg
        }

        It 'Throws if expectations are null' {
            $mock = New-PSClassMock $testClass
            $msg = "Value cannot be null."
            $msg += "`r`nParameter name: Expectations"
            { $mock | Setup-Mock -Method 'iamaproperty' -Expectations $null } | Should Throw $msg
        }
    }
}