$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# here : /branch/tests/Poshbox.Test
. "$here\..\TestCommon.ps1"

Describe 'Guard-ArgumentIsPSClass' {
    Context 'Given an object derived from a PSClass' {
        It 'Does not throw if same PSClass is provided' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            $testObject = $testClass.New()

            Guard-ArgumentIsPSClass 'testArg' $testObject $testClass
        }

        It 'Does not throw if same PSClassName is provided' {
            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru
            $testObject = $testClass.New()

            Guard-ArgumentIsPSClass 'testArg' $testObject $className
        }

        It 'Does not throw object is a derived version of the PSClass provided' {
            $className = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $className {} -PassThru
            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -Inherit $baseClass {} -PassThru

            $derivedObject = $derivedClass.New()

            Guard-ArgumentIsPSClass 'testArg' $derivedObject $baseClass
        }

        It 'Throws if object is less derived than PSClass' {
            $className = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $className {} -PassThru
            $derivedClassName = [Guid]::NewGuid().ToString()
            $derivedClass = New-PSClass $derivedClassName -Inherit $baseClass {} -PassThru

            $baseObject = $baseClass.New()

            { Guard-ArgumentIsPSClass 'testArg' $baseObject $derivedClass } | Should Throw
        }

        It 'Throws if object was not created by PSClass' {
            $object = New-PSObject
            $className = [Guid]::NewGuid().ToString()
            $baseClass = New-PSClass $className {} -PassThru

            { Guard-ArgumentIsPSClass 'testArg' $object $derivedClass } | Should Throw
        }

        It 'Throws if object is not the same class, using className' {
            $otherClassName = [Guid]::NewGuid().ToString()
            $otherClass = New-PSClass $otherClassName {} -PassThru

            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            $testObject = $testClass.New()

            { Guard-ArgumentIsPSClass 'testArg' $testObject $otherClassName } | Should Throw
        }

        It 'Throws if object is not the same class, using PSClass' {
            $otherClassName = [Guid]::NewGuid().ToString()
            $otherClass = New-PSClass $otherClassName {} -PassThru

            $className = [Guid]::NewGuid().ToString()
            $testClass = New-PSClass $className {} -PassThru

            $testObject = $testClass.New()

            { Guard-ArgumentIsPSClass 'testArg' $testObject $otherClass } | Should Throw
        }
    }
}