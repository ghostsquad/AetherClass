$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe "New-PSClass" {
    It 'cannot create two classes with the same name' {
        $className = [Guid]::NewGuid().ToString()
        $testClass = New-PSClass $className {} -PassThru
        { New-PSClass $className {} } | Should Throw
    }

    It 'can inherit using the name of a class instead of a variable of the class definition' {
        $className = [Guid]::NewGuid().ToString()
        $testClass = New-PSClass $className {} -PassThru

        $derivedClassName = [Guid]::NewGuid().ToString()
        $derivedClass = New-PSClass $derivedClassName -Inherit $className {} -PassThru
    }

    It 'can override OBJECT methods (like ToString())' {
        $className = [Guid]::NewGuid().ToString()
        $testClass = New-PSClass $className {
            method -override 'ToString' {
                return 'foo'
            }
        } -PassThru

        $sut = $testClass.New()
        $sut.ToString() | Should Be 'foo'
    }

    Context 'PassThru' {
        It 'Returns class object when given -PassThru switch' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            ($testClass -ne $null) | Should Be $true
            $testClass.__ClassName | Should Be $className
        }

        It 'has no return value without passthru, but can be accessed from Get-PSClass' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {}
            ($testClass -eq $null) | Should Be $true

            $testClass = Get-PSClass $className
            ($testClass -eq $null) | Should Be $false
            $testClass.__ClassName | Should Be $className
        }
    }

    Context "GivenStaticMethod" {
        It "runs provided script block" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "testMethod" -static {
                    return "expected"
                }
            } -PassThru
            $testClass.testMethod() | Should Be "expected"
        }
    }

    BeforeEach {
        $className = [Guid]::NewGuid().ToString()
        $testClass = New-PSClass $className {
            method "testMethodNoParams" { return "base" }
            note "foo" "base"
        } -PassThru
    }

    Context "GivenBaseClass" {
        It 'can call function:base with multiple inheritance' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "_foo" "default"
                constructor {
                    $this._foo = $args[0]
                }
            } -PassThru

            $className2 = [Guid]::NewGuid().ToString()
            $testClass2 = New-PSClass $className2 -Inherit $className {
                constructor {
                    base $args[0]
                }
            } -PassThru

            $className3 = [Guid]::NewGuid().ToString()
            $testClass3 = New-PSClass $className3 -Inherit $className2 {
                constructor {
                    base $args[0]
                }
            } -PassThru

            $expectedValue = 'i am expected'
            $sut = $testClass3.New($expectedValue)
            $sut._foo | should be $expectedValue
        }

        It "can override method with empty params" {
            $className = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $className -inherit $testClass {
                method -override "testMethodNoParams" { return "expected" }
            } -PassThru

            $newDerived = $derivedClass.New()
            $newDerived.testMethodNoParams() | Should Be "expected"
        }

        It "can call non overridden base method" {
            $className = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $className -inherit $testClass {} -PassThru
            $newDerived = $derivedClass.New()
            $newDerived.testMethodNoParams() | Should Be "base"
        }

        It "can call non overridden base note" {
            $className = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $className -inherit $testClass {} -PassThru
            $newDerived = $derivedClass.New()
            $newDerived.foo | Should Be "base"
        }

        It "can use complex objects in base constructor" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "_foo" "default"
                note "_bar" "default"
                constructor {
                    param (
                        [psobject]$a,
                        [psobject]$b
                    )
                    $this._foo = $a
                    $this._bar = $b
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                constructor {
                    Base $args[0] $args[1]
                }
            } -PassThru

            $myAObject = New-PSObject @{
                someProp = (New-PSObject @{
                    anotherProp = "foo"
                })
            }

            $myBObject = New-PSObject @{
                prop1 = (New-PSObject @{
                    prop2 = "bar"
                })
            }

            $instance = $derivedClass.New($myAObject, $myBObject)
            $instance._foo.someProp.anotherProp | Should Be $myAObject.someProp.anotherProp
            $instance._bar.prop1.prop2 | Should Be $myBObject.prop1.prop2
        }
    }

    Context "Constructor - Sunny" {
        It "can access and set defined notes" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                constructor {
                    $this._foo = "set by constructor"
                }

                note "_foo" "default"
                property "foo" { return $this._foo }
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo | Should Be "set by constructor"
        }

        It "does not call base constructor" {
            $className = [Guid]::NewGuid().ToString()
            $testBaseClass = New-PSClass $className {
                note "_foo" "default"
                constructor {
                    $this._foo = $args[0]
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $testBaseClass {} -PassThru

            $derived = $derivedClass.New('something else')
            $derived._foo | Should Be "default"
        }

        It "can call base constructor using function:base" {
            $className = [Guid]::NewGuid().ToString()
            $testBaseClass = New-PSClass $className {
                note "_foo" "default"
                constructor {
                    $this._foo = $args[0]
                }
            } -PassThru

            $expectedValue = 'i am expected'
            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $testBaseClass {
                constructor {
                    Base $args[0]
                }
            } -PassThru

            $derived = $derivedClass.New($expectedValue)
            $derived._foo | Should Be $expectedValue
        }

        It "can use multiple constructor arguments" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "_foo" "default"
                note "_bar" "default"
                constructor {
                    param($a, $b)
                    $this._foo = $a
                    $this._bar = $b
                }
            } -PassThru

            $expectedFoo = "expected foo"
            $expectedBar = "expected bar"

            $instance = $testClass.New($expectedFoo, $expectedBar)
            $instance._foo | Should Be $expectedFoo
            $instance._bar | Should Be $expectedBar
        }

        It "can use constructor args auto variable" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "_foo" "default"
                note "_bar" "default"
                constructor {
                    $this._foo = $args[0]
                    $this._bar = $args[1]
                }
            } -PassThru

            $expectedFoo = "expected foo"
            $expectedBar = "expected bar"

            $instance = $testClass.New($expectedFoo, $expectedBar)
            $instance._foo | Should Be $expectedFoo
            $instance._bar | Should Be $expectedBar
        }

        It "can use complex objects in constructor" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "_foo" "default"
                note "_bar" "default"
                constructor {
                    param (
                        [psobject]$a,
                        [psobject]$b
                    )
                    $this._foo = $a
                    $this._bar = $b
                }
            } -PassThru

            $myAObject = New-PSObject @{
                someProp = (New-PSObject @{
                    anotherProp = "foo"
                })
            }

            $myBObject = New-PSObject @{
                prop1 = (New-PSObject @{
                    prop2 = "bar"
                })
            }

            $instance = $testClass.New($myAObject, $myBObject)
            $instance._foo.someProp.anotherProp | Should Be $myAObject.someProp.anotherProp
            $instance._bar.prop1.prop2 | Should Be $myBObject.prop1.prop2
        }
    }

    Context "Construction - Rainy" {
        It "Throws when attempting to add multiple static methods with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                method "testMethod" -static {}
                method "testMethod" -static {}
              }
            } | Should Throw
        }

        It "Throws when attempting to add multiple methods with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                method "testMethod" {}
                method "testMethod" {}
              }
            } | Should Throw
        }

        It "Throws when attempting to add multiple properties with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                property "testProp" {}
                property "testProp" {}
              }
            } | Should Throw
        }

        It "Throws when attempting to add multiple notes with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                note "testNote"
                note "testNote"
              }
            } | Should Throw
        }

        It "Throws when attempting to override a method if method does not exist" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {}

            $derivedClassName = [Guid]::NewGuid().ToString()
            { $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                method -override "doesnotexist" {}
              }
            } | Should Throw
        }

        It "Throws when attempting to override a method if params are different" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "testMethod" {}
            }

            $derivedClassName = [Guid]::NewGuid().ToString()
            { $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                method -override "testMethod" {param($a)}
              }
            } | Should Throw
        }

        It "Throws when attempting to override a property if set is defined in base and not in derived" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property "testProp" {} -Set {}
            }

            $derivedClassName = [Guid]::NewGuid().ToString()
            { $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                property -override "testProp" {param($a)}
              }
            } | Should Throw
        }

        It "Throws when attempting to define a note that already exists" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note "testNote" "base"
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            { $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                note "testNote" "derived"
              }
            } | Should Throw
        }
    }
}