<#############################################################################
The AetherClass module adds "Classes" to Powershell. A Class in .NET is
essentially a definition of an object. When a new object is created, it
contains the private and public methods, fields (notes) & properties according
to the class definition. In the same way, we can do that in PowerShell. New-PSClass
allows you to define the properties, notes, & methods that should be attached to
a PSObject when it is created. Aether.Class also enables inheritance &
code contracts (think abstract class or interface), which is simply put, allows
multiple class definitions to be combined (& overwritten) upon creation of the object.

Static methods are also supported, and are become methods attached to the Class object
as expected. Using static methods/properties, allows decluttering of the Global scope,
as well as easy/reliable access to variables that would be guaranteed to exist
(because they are defined in the class).

Copyright (c) 2014 Wes McNamee

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

#############################################################################>

@{
      ModuleToProcess = 'AetherClass.psm1'

        ModuleVersion = '0.1.7'

                 GUID = '6A8B9F36-50C2-4794-AFD5-9F59263E9080'

               Author = 'Weston McNamee'

          CompanyName = 'GhostSquad'

            Copyright = 'Copyright 2014 Weston McNamee'

          Description = 'The Aether.Class module adds "Classes" to Powershell. A Class in .NET is essentially a definition of an object. When a new object is created, it contains the private and public methods, fields (notes) & properties according to the class definition. In the same way, we can do that in PowerShell. New-PSClass allows you to define the properties, notes, & methods that should be attached to a PSObject when it is created. AetherClass also enables inheritance & code contracts (think abstract class or interface), which is simply put, allows multiple class definitions to be combined (& overwritten) upon creation of the object. Static methods are also supported, and are become methods attached to the Class object as expected. Using static methods/properties, allows decluttering of the Global scope, as well as easy/reliable access to variables that would be guaranteed to exist (because they are defined in the class).'

    PowerShellVersion = '3.0'

         NestedModules = @(
                        'AetherCore'
                        'PSCX'
                        )

      FunctionsToExport = @(
                        'Attach-PSClassConstructor'
                        'Attach-PSClassMethod'
                        'Attach-PSClassNote'
                        'Attach-PSClassProperty'
                        'Get-PSClass'
                        'Guard-ArgumentIsPSClassDefinition'
                        'Guard-ArgumentIsPSClassInstance'
                        'ItIs'
                        'ItIs-Any'
                        'ItIs-Expression'
                        'ItIs-In'
                        'ItIs-InRange'
                        'ItIs-NotIn'
                        'ItIs-NotNull'
                        'ItIs-Regex'
                        'New-PSClass'
                        'New-PSClassInstance'
                        'New-PSClassMock'
                        'ObjectIs-PSClassInstance'
                        )

             FileList = @(
                        'LICENSE'
                        'AetherClass.psd1'
                        'AetherClass.psm1'
                        'AetherClass.dll'
                        'functions\Attach-PSClassConstructor.ps1'
                        'functions\Attach-PSClassMethod.ps1'
                        'functions\Attach-PSClassNote.ps1'
                        'functions\Attach-PSClassProperty.ps1'
                        'functions\Get-PSClass.ps1'
                        'functions\Guard-ArgumentIsPSClassDefinition.ps1'
                        'functions\Guard-ArgumentIsPSClassInstance.ps1'
                        'functions\ItIs.ps1'
                        'functions\ItIs-Any.ps1'
                        'functions\ItIs-Expression.ps1'
                        'functions\ItIs-In.ps1'
                        'functions\ItIs-InRange.ps1'
                        'functions\ItIs-NotIn.ps1'
                        'functions\ItIs-NotNull.ps1'
                        'functions\ItIs-Regex.ps1'
                        'functions\New-PSClass.ps1'
                        'functions\New-PSClassInstance.ps1'
                        'functions\New-PSClassMock.ps1'
                        'functions\ObjectIs-PSClassInstance.ps1'
                        'functions\FormatCallCount.ps1'
                        'functions\FormatInvocation.ps1'
                        'functions\AssertMemberType.ps1'
                        )

          PrivateData = @{
                            PSData = @{
                                Tags = 'gravity class psclass'
                                LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
                                ProjectUri = 'https://github.com/GhostSquad/AetherClass'
                                IconUri = ''
                                ReleaseNotes = ''
                            }
                        }
}