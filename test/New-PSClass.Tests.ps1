$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\..\TestCommon.ps1"

Describe 'New-PSClass' {
    Context 'Sunny' {
        It 'Class Creation - Given -PassThru, returns class object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            ($testClass -ne $null) | Should Be $true
            $testClass.__ClassName | Should Be $className
        }

        It 'Class Creation - Omitting -PassThru, returns null' {
            $className = [Guid]::NewGuid().ToString()
            $result = New-PSClass $className {}
            ($result -eq $null) | Should Be $true
        }

        It 'Class Creation - Class can be accessed using Get-PSClass' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {}
            ($testClass -eq $null) | Should Be $true

            $testClass = Get-PSClass $className
            ($testClass -eq $null) | Should Be $false
            $testClass.__ClassName | Should Be $className
        }

        It 'Inheritance - Can inherit using class name string' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -Inherit $className {} -PassThru

            $derivedClass.__ClassName | Should Be $derivedClassName
            $derivedClass.__BaseClass.__ClassName | Should Be $className
        }

        It 'Inheritance - Can inherit using class object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -Inherit $testClass {} -PassThru

            $derivedClass.__ClassName | Should Be $derivedClassName
            $derivedClass.__BaseClass.__ClassName | Should Be $className
        }

        It 'Inheritance - Can inherit using class object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -Inherit $testClass {} -PassThru

            $derivedClass.__ClassName | Should Be $derivedClassName
            $derivedClass.__BaseClass.__ClassName | Should Be $className
        }

        It 'Notes - can get default value-typed note values' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'foo' 'default value'
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo | Should Be 'default value'
        }

        It 'Notes - can get constructor defined note values' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                constructor {
                    breakpoint
                    $this.foo = 'set by constructor'
                }

                note 'foo'
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo | Should Be 'set by constructor'
        }

        It 'Notes - constructor sets note value after default is set' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                constructor {
                    $this.foo = 'set by constructor'
                }

                note 'foo' 'default'
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo | Should Be 'set by constructor'
        }

        It 'Notes - Overriding - can get non overridden base note' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note "baseNote" "base"
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {} -PassThru

            $newDerived = $derivedClass.New()
            $newDerived.baseNote | Should Be "base"
        }

        It 'Properties - getter invoked when called' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                property 'foo' {return 'default value'}
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo | Should Be 'default value'
        }

        It 'Properties - setter invoked when set' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'bar'
                property 'foo' {} {$this.bar = $args[0]}
            } -PassThru

            $testObj = $testClass.New()
            $testObj.foo = 'expected'
            $testObj.bar | Should Be 'expected'
        }

        It 'Properties - Overriding - can get non overridden base property' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                property "baseProperty" { return "base" }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {} -PassThru

            $newDerived = $derivedClass.New()
            $newDerived.baseProperty | Should Be "base"
        }

        It 'Methods - Overriding - Can override [object] methods like ToString()' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method -override 'ToString' {
                    return 'foo'
                }
            } -PassThru

            $sut = $testClass.New()
            $sut.ToString() | Should Be 'foo'
        }

        It 'Methods - Overriding - Can override method with empty params' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                method "testMethodNoParams" { return "base" }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                method -override "testMethodNoParams" { return "expected" }
            } -PassThru

            $newDerived = $derivedClass.New()
            $newDerived.testMethodNoParams() | Should Be "expected"
        }

        It 'Methods - Overriding - can call non overridden base method' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                method "baseMethod" { return "base" }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {} -PassThru

            $newDerived = $derivedClass.New()
            $newDerived.baseMethod() | Should Be "base"
        }

        It 'Methods - Static - Accessible from class object' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                method "testMethod" -static {
                    return "expected"
                }
            } -PassThru
            $testClass.testMethod() | Should Be "expected"
        }

        It 'Instance Construction - Handles single parameter' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'note1'
                constructor {
                    param (
                        $note1
                    )

                    $this.note1 = $note1
                }
            } -PassThru

            $instance = $testClass.New('expected1')
            $instance.note1 | Should Be 'expected1'
        }

        It 'Instance Construction - Handles multiple params' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'note1'
                note 'note2'
                constructor {
                    param (
                        $note1,
                        $note2
                    )

                    $this.note1 = $note1
                    $this.note2 = $note2
                }
            } -PassThru

            $instance = $testClass.New('expected1', 'expected2')
            $instance.note1 | Should Be 'expected1'
            $instance.note2 | Should Be 'expected2'
        }

        It 'Instance Construction - Handles unnamed args' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'note1'
                note 'note2'
                constructor {
                    param (
                        $note1
                    )

                    $this.note1 = $note1
                    $this.note2 = $args[0]
                }
            } -PassThru

            $instance = $testClass.New('expected1', 'expected2')
            $instance.note1 | Should Be 'expected1'
            $instance.note2 | Should Be 'expected2'
        }

        It 'Instance Construction - Handles collection with single element' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'collection1'
                constructor {
                    param (
                        $collection1
                    )

                    $this.collection1 = $collection1
                }
            } -PassThru

            $expectedCollection1 = @(1)

            $instance = $testClass.New($expectedCollection1)
            $instance.collection1.GetType() | Should Be ([System.Object[]])

            $instance.collection1.Count | Should Be 1
        }

        It 'Instance Construction - Handles Collections' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {
                note 'collection1'
                note 'collection2'
                constructor {
                    param (
                        $collection1,
                        $collection2
                    )

                    $this.collection1 = $collection1
                    $this.collection2 = $collection2
                }
            } -PassThru

            $expectedCollection1 = @(1,2,3)
            $expectedCollection2 = @(1,2,3,4,5)

            $instance = $testClass.New($expectedCollection1, $expectedCollection2)
            $instance.collection1.GetType() | Should Be ([System.Object[]])
            $instance.collection2.GetType() | Should Be ([System.Object[]])

            $instance.collection1.Count | Should Be 3
            $instance.collection2.Count | Should Be 5
        }

        It 'Instance Construction - Inheritance - Can pass single param to base class' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note 'note1'
                constructor {
                    param (
                        $note1
                    )

                    $this.note1 = $note1
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                constructor {
                    param (
                        $value
                    )

                    base $value
                }
            } -PassThru

            $instance = $derivedClass.New('expected1')
            $instance.note1 | Should Be 'expected1'
        }

        It 'Instance Construction - Inheritance - Performs remaining construction after base call' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note 'note1'
                constructor {
                    param (
                        $note1
                    )

                    $this.note1 = $note1
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                constructor {
                    param (
                        $value
                    )

                    base $value

                    $this.note1 = 'set later'
                }
            } -PassThru

            $instance = $derivedClass.New('expected1')
            $instance.note1 | Should Be 'set later'
        }

        It 'Instance Construction - Inheritance - Can pass multiple params to base class' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note 'note1'
                note 'note2'
                constructor {
                    param (
                        $note1,
                        $note2
                    )

                    $this.note1 = $note1
                    $this.note2 = $note2
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                constructor {
                    param (
                        $value,
                        $value2
                    )

                    base $value $value2
                }
            } -PassThru

            $instance = $derivedClass.New('expected1', 'expected2')
            $instance.note1 | Should Be 'expected1'
            $instance.note2 | Should Be 'expected2'
        }

        It 'Instance Construction - Inheritance - Can pass multiple params to extended base chain' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note 'note1'
                note 'note2'
                constructor {
                    param (
                        $note1,
                        $note2
                    )

                    $this.note1 = $note1
                    $this.note2 = $note2
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                constructor {
                    param (
                        $value,
                        $value2
                    )

                    base $value $value2
                }
            } -PassThru

            $moreDerivedClassName = [Guid]::NewGuid().ToString()
            $moreDerivedClass = New-PSClass $moreDerivedClassName -inherit $derivedClassName {
                constructor {
                    param (
                        $object1,
                        $object2
                    )

                    base $object1 $object2
                }
            } -PassThru

            $instance = $moreDerivedClass.New('expected1', 'expected2')
            $instance.note1 | Should Be 'expected1'
            $instance.note2 | Should Be 'expected2'
        }

        It 'Instance Construction - Inheritance - Extended base chain handles collections properly' {
            $baseClassName = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $baseClassName {
                note 'collection1'
                note 'collection2'
                constructor {
                    param (
                        $collection1,
                        $collection2
                    )

                    $this.collection1 = $collection1
                    $this.collection2 = $collection2
                }
            } -PassThru

            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -inherit $baseClass {
                constructor {
                    param (
                        $value,
                        $value2
                    )

                    base $value $value2
                }
            } -PassThru

            $moreDerivedClassName = [Guid]::NewGuid().ToString()
            $moreDerivedClass = New-PSClass $moreDerivedClassName -inherit $derivedClassName {
                constructor {
                    param (
                        $object1,
                        $object2
                    )

                    base $object1 $object2
                }
            } -PassThru

            $expectedCollection1 = @(1,2,3)
            $expectedCollection2 = @(1,2,3,4,5)

            $instance = $moreDerivedClass.New($expectedCollection1, $expectedCollection2)
            $instance.collection1.GetType() | Should Be ([System.Object[]])
            $instance.collection2.GetType() | Should Be ([System.Object[]])

            $instance.collection1.Count | Should Be 3
            $instance.collection2.Count | Should Be 5
        }

        It 'Scope - Can access variable from outside of module scope' {
            $mytestvariable = 'i am a test variable'

            $testClassName = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $testClassName {
                method 'getoutside' {
                    return $mytestvariable
                }
            } -PassThru

            $sut = $testClass.New()

            $sut.getoutside() | Should Be $mytestvariable
        }
    }

    Context 'Rainy' {
        It 'Class Creation - Given existing class, throws when trying to create it again' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            { New-PSClass $className {} } | Should Throw
        }

        It "Class Creation - Throws when attempting to add multiple static methods with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                method "testMethod" -static {}
                method "testMethod" -static {}
              }
            } | Should Throw
        }

        It "Class Creation - Throws when attempting to add multiple methods with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                method "testMethod" {}
                method "testMethod" {}
              }
            } | Should Throw
        }

        It "Class Creation - Throws when attempting to add multiple properties with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                property "testProp" {}
                property "testProp" {}
              }
            } | Should Throw
        }

        It "Class Creation - Throws when attempting to add multiple notes with same name" {
            $className = [Guid]::NewGuid().ToString()
            { New-PSClass $className {
                note "testNote"
                note "testNote"
              }
            } | Should Throw
        }

        It "Class Creation - Throws when attempting to override a method if method does not exist" {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {}

            $derivedClassName = [Guid]::NewGuid().ToString()
            { $derivedClass = New-PSClass $derivedClassName -inherit $testClass {
                method -override "doesnotexist" {}
              }
            } | Should Throw
        }

        It "Class Creation - Throws when attempting to override a method if params are different" {
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

        It "Class Creation - Throws when attempting to override a property if set is defined in base and not in derived" {
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

        It "Class Creation - Throws when attempting to define a note that already exists" {
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