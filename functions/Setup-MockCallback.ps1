function Setup-MockCallBack {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$SetupInfo
    )

    Guard-ArgumentIsPSClassInstance 'Mock' $Mock 'GpClass.Mock'
}