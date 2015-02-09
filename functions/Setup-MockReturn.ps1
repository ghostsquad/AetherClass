function Setup-MockReturn {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [psobject]$Mock
    )
}