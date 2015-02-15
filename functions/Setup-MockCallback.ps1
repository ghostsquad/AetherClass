function Setup-MockCallBack {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$SetupInfo,

        [parameter(position=0)]
        [Action]$Action

        [switch]$PassThru
    )

    Guard-ArgumentIsPSClassInstance 'SetupInfo' $SetupInfo 'GpClass.Mock.SetupInfo'

    $SetupInfo.CallBackAction = $Action

    if($PassThru) {
        return $SetupInfo
    }
}