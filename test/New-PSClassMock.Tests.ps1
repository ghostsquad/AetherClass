$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\TestCommon.ps1"

Describe "New-PSClassMock" {
    It 'Can generate mock from ClassName' {
        $className = [Guid]::NewGuid().ToString()
        New-PSClass $className {}

        { New-PSClassMock $className } | Should Not Throw
    }

    It 'Can generate mock from Class Object' {
        $className = [Guid]::NewGuid().ToString()
        $testClass = New-PSClass $className {} -PassThru

        { New-PSClassMock $testClass } | Should Not Throw
    }

    Context "Method Mocking" {
        BeforeEach {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    throw "not implemented"
                }
            } -PassThru
        }

        It "Can mock method using generic 'setup'" {
            $mock = New-PSClassMock $testClass
            { $mock.Setup('Foo', {return "i am a test"}) } | Should Not Throw
            $mock.Object.foo() | Should Be "i am a test"
        }

        It "Given Non-Strict, No Expectation, methods do nothing, return null" {
            $mock = New-PSClassMock $testClass
            { $mock.Object.foo() } | Should Not Throw
        }

        It 'Can provide multiple setups' {

        }

        It "Given -Strict, No Expectation, should throw PsMockException" {
            $mock = New-PSClassMock $testClass -Strict

            $errorRecord = $null
            try {
                $mock.Object.foo()
            } catch {
                $errorRecord = $_
            }

            ($errorRecord -eq $null) | Should Be $false
            $errorRecord.Exception.GetBaseException().GetType() | Should Be ([PSMockException])
        }

        It "Given method with Expectation, provided Expectation is used" {
            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    return "bar"
                })

            $mockedObject = $mock.Object

            $mock.Object.foo() | Should Be "bar"
        }

        It "Given non-matching method parameters, should throw PsMockException" {
            $mock = New-PSClassMock $testClass
            { $mock.SetupMethod("foo", {
                    param($a)
                }) } | Should Throw
        }

        It "Can use variables from test case using GetNewClosure" {
            $mock = New-PSClassMock $testClass
            $expectedReturn = "i am expected"

            $mock.SetupMethod("foo", {
                return $expectedReturn
            }.GetNewClosure())

            $mock.Object.foo() | Should Be $expectedReturn
        }

        It "Mock.Verify, non-equivalent parameter, should throw PsMockException" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    param($a)
                }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    param($a)
                })

            [Void]$mock.Object.foo(1)

            { $mock.Verify("foo", 2) } | Should Throw
        }

        It "Mock.Verify, equivalent parameter, does not throw" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    param($a)
                }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    param($a)
                })

            [void]$mock.Object.foo(1)

            { $mock.Verify('foo', 1) } | Should Not Throw
        }

        $verifyParamsInputDiff = @(
            @{a = 1; b = 2},
            @{a = 2; b = 1},
            @{a = 1; b = $null},
            @{a = 1; b = "I'm different"},
            @{a = {param($n) $n -eq 2}; b = 1}
            @{a = {param($n) $n -eq 1}; b = {param($n) $n -eq 2};}
        )
        It "Mock.Verify, multiple non-equivalent params, should throw PsMockException: <a> <b>" `
            -TestCases $verifyParamsInputDiff {

            param( $a, $b )

            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    param($a, $b)
                }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    param($a, $b)
                })

            [Void]$mock.Object.foo(1,1)

            $param1expectation = {$args[0] -eq $a}.GetNewClosure()
            $param2expectation = {$args[0] -eq $b}.GetNewClosure()
            { $mock.Verify('foo', @($param1expectation, $param2expectation)) } | Should Throw
        }

        It "mock.Verify, multiple equivalent params, does not throw" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    param($a, $b)
                }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    param($a, $b)
                })

            [Void]$mock.Object.foo(1,1)

            $expectation = {$args[0] -eq 1}.GetNewClosure()
            { $mock.Verify('foo', @($expectation, $expectation)) } | Should Not Throw
        }

        It "can get method invocation info" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "foo" {
                    param($a, $b)
                }
            } -PassThru

            $mock = New-PSClassMock $testClass
            $mock.SetupMethod("foo", {
                    param($a, $b)
                })

            $expectedA = 'expectedA'
            $expectedB = 'expectedB'
            [Void]$mock.Object.foo($expectedA, $expectedB)

            $mock.Verify

            $mock._mockedMethods["foo"].Invocations.Count | Should Be 1
            $mock._mockedMethods["foo"].Invocations[0].Count | Should Be 2
            $mock._mockedMethods["foo"].Invocations[0][0] | Should Be $expectedA
            $mock._mockedMethods["foo"].Invocations[0][1] | Should Be $expectedB
        }
    }

    Context "Note Mocking" {
        BeforeEach {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "myNote" "im a test"
            } -PassThru
        }

        It "Can mock note getter using generic 'setup'" {
            $mock = New-PSClassMock $testClass
            { $mock.Setup('myNote', "i am a test") } | Should Not Throw
            $mock.Object.myNote | Should Be "i am a test"
        }

        It "Can mock note setter using generic 'setup'" {
            $mock = New-PSClassMock $testClass

            $actualValue = $null

            { $mock.Setup('myNote', $null, [ref]$actualValue) } | Should Not Throw
            $mock.Object.myNote = "i am a test"
            $actualValue | Should Be "i am a test"
        }

        It "Includes notes from class" {
            $mock = New-PSClassMock $testClass
            $mock.Object.myNote | Should Be $null
        }

        It "Given Non-Strict, Expectation Set, note getter should return expected value" {
            $expectedValue = "im expected"

            $mock = New-PSClassMock $testClass -Strict
            $mock.SetupNoteGet("myNote", $expectedValue)

            $mock.Object.myNote | Should Be $expectedValue
        }

        It "Given Non-Strict, Expectation Set, note setter value should be trackable" {
            $mock = New-PSClassMock $testClass -Strict
            $actualValue = $null

            $mock.SetupNoteSet("myNote", [ref]$actualValue)

            $expectedValue = "foo"

            $mock.Object.myNote = $expectedValue

            $actualValue | Should Be $expectedValue
        }
    }

    Context "Property Mocking" {
        BeforeEach {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property "myProp" { return "im a test" }
            } -PassThru
        }

        It "Can mock property getter using generic 'setup'" {
            $mock = New-PSClassMock $testClass
            { $mock.Setup('myProp', "i am a test") } | Should Not Throw
            $mock.Object.myProp | Should Be "i am a test"
        }

        It "Can mock property setter using generic 'setup'" {
            $mock = New-PSClassMock $testClass

            $actualValue = $null

            { $mock.Setup('myProp', $null, [ref]$actualValue) } | Should Not Throw
            $mock.Object.myProp = "i am a test"
            $actualValue | Should Be "i am a test"
        }

        It "Includes properties from class" {
            $mock = New-PSClassMock $testClass
            $mock.Object.myProp | Should Be $null
        }

        It "Given Non-Strict, Expectation Set, property getter should return expected value" {
            $mock = New-PSClassMock $testClass -Strict

            $expectedValue = "im expected"

            $mock.SetupPropertyGet("myProp", $expectedValue)

            $mock.Object.myProp | Should Be $expectedValue
        }

        It "Given Non-Strict, Expectation Set, property setter value should be trackable" {
            $mock = New-PSClassMock $testClass -Strict
            $actualValue = $null

            $mock.SetupPropertySet("myProp", [ref]$actualValue)

            $expectedValue = "expectedVal"

            $mock.Object.myProp = $expectedValue

            $actualValue | Should Be $expectedValue
        }
    }
}