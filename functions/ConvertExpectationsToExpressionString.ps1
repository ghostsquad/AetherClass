function ConvertExpectationsToExpressionString {
    [cmdletbinding()]
    param (
        [func[object, bool][]]$Expectations = @()
    )

    $FuncStrings = @()
    foreach($expectation in $Expectations) {
        $FuncStrings += "{" + $expectation.Target.Constants[0].ToString().Trim("`n").Trim() + "}"
        breakpoint
    }

    return [string]::Join(", ", $FuncStrings)
}