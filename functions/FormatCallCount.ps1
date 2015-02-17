function FormatCallCount {
    param (
        [int]$CallCount
    )

    if ($callCount -eq 0) {
       return "Times.Never";
    }

    if ($callCount -eq 1){
       return "Times.Once";
    }

    $cultureInfo = [System.Globalization.CultureInfo]::CurrentCulture
    return [string]::Format($cultureInfo, "Times.Exactly({0})", $callCount);
}