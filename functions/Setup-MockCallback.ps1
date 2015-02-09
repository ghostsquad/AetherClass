function Setup-MockCallBack {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$Mock
    )
}