AetherClass
===========

Bringing Polymorphism &amp; Inheritance to PSObjects.

So What Is It?
===========

In short, it makes this better:

```Powershell
Add-Type -TypeDefinition @"
public Class Foo {
    // yada yada
}
"@
```
What's wrong with this? There's nothing necessarily wrong with C#, but there are some interesting gotchas and intricacies that you should know when mixing C# and Powershell. Such as debugging.

Ok, so how about this?
```Powershell
function New-Foo {
    $o = new-object
    $o | Add-Member -MemberType Note -Name "MyNote" -Value "Bar"

    return $o
}
```

Actually, this kind of thing is exactly what we are doing in the background, but with a few extra layers that add features and compiler-like validation steps.

Features:

- Inheritance

   Layering object creation, while maintaining code contracts

   ```Powershell
   PS> New-PSClass 'Animal' {
     Method 'Speak' {
        Write-Host 'Hello World!'
     }
   }
   
   PS> New-PSClass 'SingingAnimal' -Inherit 'Animal' {
     Method 'Sing' {
        Write-Host 'La La La La!'
     }
   }

   $instance = New-PSClassInstance 'SingingAnimal'
   PS> Get-Member -InputObject $instance


   TypeName: SingingAnimal

Name                   MemberType   Definition
----                   ----------   ----------
...
__ClassDefinition__    NoteProperty Aether.Class.PSClassDefinition ...
Sing                   ScriptMethod System.Object Sing();
Speak                  ScriptMethod System.Object Speak();
   ```
   New-PSClass won't let you methods on subclasses that exist on parent classes without explicitly using `-override` (eg. `method -override mymethod {}`). In addition, if you try to override a method that doesn't exist on the parent (or farther up the tree), you will also get an exception. This is the compiler-like validation in action. More on this in the [WIKI](https://github.com/ghostsquad/AetherClass/wiki)!

- Polymorphism

   Each object that's created has an inheritance hierarchy, and that makes it possible to assert that the object you are receiving meets the code contract.

   ```Powershell
   # forcing .NET type parameters
   function foo {
      param (
         [System.IO.FileInfo]$FileInfo
      )
   }

   # forcing PSClass type parameters
   function foo {
      param (
         [PSObject]$Animal
      )

      Guard-ArgumentIsPSClassInstance 'Animal' $Animal 'MyNamespace.Animals.AnimalBase'
   }
   ```   
   More on this in the [WIKI](https://github.com/ghostsquad/AetherClass/wiki)!

More Than Syntactical Sugar
===========

Have you ever written something like this, and wondered, how to write tests that don't require modifications to the underlying filesystem?

```Powershell
# don't bash the example for not being idempotent
function Update-Files {
    param (
        [string]$PathRoot
    )

    $files = Get-ChildItem $PathRoot
    foreach($file in $files) {
        $content = Get-Content $file.FullName
        $lines = $content.Count
        $content += "Lines: {0}" -f $lines
        $content | Out-File $file.FullName
    }
}
```

This is just a simple example showing a tight-coupling to several built-in cmdlets, and ultimately the FileSystem that the code is being run against.

**How would you test this?**
You could use a framework like Pester, and Mock the Get-ChildItem, Get-Content, and Out-File functions, But will your test survive if it's refactored for increased performance and reduced memory overhead like this?

```Powershell
# don't bash the example for not being idempotent
function Update-Files {
    param (
        [string]$PathRoot
    )

    # this returns a enumerator of strings 
    # instead of a full collection FileInfo objects, which will be faster and use less memory
    $filesEnumerator = [System.IO.Directory]::EnumerateFiles($PathRoot)
    while($filesEnumerator.MoveNext()) {
        # ReadAllText is a bit faster than Get-Content
        $content = [System.IO.File]::ReadAllLines($filesEnumerator.Current)
        $lines = $content.Count
        $content += "Lines: {0}" -f $lines
        # WriteAllText is faster than Out-File
        [System.IO.File]::WriteAllText($filesEnumerator.Current, `
                [string]::Join([Environment]::NewLine, $content))
    }
}
```

Not only will your test not survive this refactor, but you may actually endup up modifying files on your filesystem the first time you run your test. There are lots of articles like [Test Behavior Not Implementation](http://googletesting.blogspot.com/2013/08/testing-on-toilet-test-behavior-not.html) that explain how to write good tests. I highly suggest reading these if you aren't familiar with concepts like Dependency Injection, Behavior-Driven Development and Test-Driven Development.

### How can I do this right?

Consider the following script and test examples using PSClass and PSClassMock.

##### Your Script
```Powershell
New-PSClass 'WindowsEnvironment' {
    method 'EnumerateFiles' {
        param ([string]$Path)
        return [System.IO.Directory]::EnumerateFiles($Path)
    }

    method 'WriteAllText' {
        param ([string]$Path, [string]$Content)
        [System.IO.File]::WriteAllText($Path, $content)
    }

    method 'ReadAllLines' {
        param ([string]$Path)
        return [System.IO.File]::ReadAllLines($Path)
    }
}

New-PSClass 'Scripts.UpdateFilesCommand' {
    note Environment

    constructor {
        param($Environment)
        Guard-ArgumentIsPSClassInstance Environment $Environment 'WindowsEnvironment'
        $this.Environment = $Environment
    }

    method Execute() {
        $filesEnumerator = $this.Environment.EnumerateFiles($PathRoot)
        while($filesEnumerator.MoveNext()) {
            $content = $this.Environment.ReadAllLines($filesEnumerator.Current)
            $lines = $content.Count
            $content += "Lines: {0}" -f $lines
            $this.Environment.WriteAllText($filesEnumerator.Current, `
                [string]::Join([Environment]::NewLine, $content))
        }
    }
}

function Update-Files {
    param (
        [string]$PathRoot
    )

    $Environment = New-PSClassInstance 'WindowsEnvironment'
    $UpdateFilesCommand = New-PSClassInstance 'Scripts.UpdateFilesCommand' -ArgumentList @(
        $Environment
    )
    
    $UpdateFilesCommand.Execute()
}
```
##### Your Tests
```Powershell
# Using Pester Syntax for tests

New-PSClass 'IEnumerator' {
    method 'MoveNext' {}
    property 'Current' {}
}

Describe 'Scripts.UpdateFilesCommand' {
    It 'Adds a Line Count to end of file' {
        $i = 0;
        $mockEnumerator = New-PSClassMock 'IEnumerator'
        $mockEnumerator.Setup('MoveNext').Returns({ $script:i++ -eq 0 }.GetNewClosure())

        $mockEnvironment = New-PSClassMock 'WindowsEnvironment'
        $mockEnvironment.Setup('EnumerateFiles').Returns($mockEnumerator.Object)
        $mockEnvironment.Setup('ReadAllText').Returns(@())

        $expectation1 = ItIs-Any ([object])
        $expectation2 = ItIs ([Environment]::NewLine + 'Lines: 0')
        $mockEnvironment.Setup('WriteAllText', @($expectation1, $expectation2))
    }
}
```

You'll see that we create a concrete psclass that simply delegates to well tested methods from .NET. By creating a psclass around the .NET methods, we can mock this behavior to allowing testing of our own code without touching the filesystem. We are also creating a `UpdateFilesCommand` psclass that will do all the heavy lifting. The `Update-Files` function now serves as the [composition root](http://visualstudiomagazine.com/articles/2014/06/01/how-to-refactor-for-dependency-injection.aspx). The only major part that's missing here is the end2end test that validates that you wrote your composition root correctly. Everything else can be taken apart, and unit tested.

I consider every public function/cmdlet as a "mini application". They should not rely on variables in parent scopes, or the global scope whenever possible. Dependencies not in your direct control (like config files), should be initialized as early as possible to see the error before any work begins. Failing early is key. That's essentially what a compiler is doing for you. Helping you fail early. We don't have that luxury in PowerShell, so there's a balancing act, and it puts more responsibility on the developer to do it right.
