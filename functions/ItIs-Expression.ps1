function ItIs-Expression {
    [cmdletbinding()]
    param (
        [scriptblock]$Expression
    )

    Guard-ArgumentNotNull 'Expression' $Expression

    $callStack = Get-PSCallStack

    if($callStack.Count -ge 2 -and ($callStack[1].Command -like 'ItIs-*' -or $callStack[1].Command -eq 'ItIs')) {
        $expStr = $callStack[1].Command + $callStack[1].Arguments
    } else {
        $expStr = $Expression.ToString()
    }

    $expressionInstance = New-PSClassInstance 'GpClass.Mock.Expression' -ArgumentList @(
        $Expression,
        $expStr
    )

    return $expressionInstance
}