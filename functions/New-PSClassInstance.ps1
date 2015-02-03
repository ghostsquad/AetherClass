function New-PSClassInstance {
    param (
        [string]$ClassName,
        [object[]]$ArgumentList
    )

    if($ArgumentList -eq $null) {
        $ArgumentList = $args
    }

    $private:PSClass = Get-PSClass $ClassName

    if($PSClass -eq $null) {
        throw (new-object ArgumentException(("A PSClass with name {0} cannot be found." -f $ClassName)))
    }

    $private:p1, $private:p2, $private:p3, $private:p4, $private:p5, $private:p6, `
        $private:p7, $private:p8, $private:p9, $private:p10 = $ArgumentList
    switch($ArgumentList.Count) {
        0 {  return $private:PSClass.New() }
        1 {  return $private:PSClass.New($p1) }
        2 {  return $private:PSClass.New($p1, $p2) }
        3 {  return $private:PSClass.New($p1, $p2, $p3) }
        4 {  return $private:PSClass.New($p1, $p2, $p3, $p4) }
        5 {  return $private:PSClass.New($p1, $p2, $p3, $p4, $p5) }
        6 {  return $private:PSClass.New($p1, $p2, $p3, $p4, $p5, $p6) }
        7 {  return $private:PSClass.New($p1, $p2, $p3, $p4, $p5, $p6, $p7) }
        8 {  return $private:PSClass.New($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) }
        9 {  return $private:PSClass.New($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9) }
        10 { return $private:PSClass.New($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10) }
        default {
            throw (new-object PSClassException("PSClass does not support more than 10 arguments for a constructor."))
        }
    }
}