module Common exposing (..)

import Round
import Routing
import String.Ext as String
import Types exposing (Model)



-- 🛠


base : Model -> String
base model =
    case model.foundation of
        Just foundation ->
            model.route
                |> Routing.treePathSegments
                |> (::) foundation.unresolved
                |> String.join "/"
                |> String.append
                    (if foundation.isDnsLink then
                        "https://"

                     else
                        "https://ipfs.runfission.com/ipfs/"
                    )

        Nothing ->
            ""


defaultCid : String
defaultCid =
    "boris.fission.name"


ifThenElse : Bool -> a -> a -> a
ifThenElse condition x y =
    if condition then
        x

    else
        y


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
