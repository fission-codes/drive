module Common exposing (..)

import Round
import String.Ext as String



-- 🛠


sizeInWords : Int -> String
sizeInWords sizeInBytes =
    let
        size =
            toFloat sizeInBytes
    in
    if size / 1000000000 > 1.05 then
        humanReadableFloat (size / 1000000000) ++ " GB"

    else if size / 1000000 > 1.05 then
        humanReadableFloat (size / 1000000) ++ " MB"

    else if size / 1000 > 1.05 then
        humanReadableFloat (size / 1000) ++ " KB"

    else
        humanReadableFloat size ++ " B"


humanReadableFloat : Float -> String
humanReadableFloat =
    Round.round 2 >> String.chopEnd ".00"
