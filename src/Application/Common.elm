module Common exposing (..)


sizeInWords : Int -> String
sizeInWords sizeInBytes =
    if toFloat sizeInBytes / 1000000 > 2 then
        String.fromInt (sizeInBytes // 1000000) ++ "MB"

    else
        String.fromInt (sizeInBytes // 1000) ++ "KB"
