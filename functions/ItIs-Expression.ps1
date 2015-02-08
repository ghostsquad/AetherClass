function ItIs-Expression {
    [cmdletbinding()]
    param (
        [func[object,bool]]$Expression
    )

    Guard-ArgumentNotNull 'Expression' $Expression

    return $Expression
}