module Common exposing (..)

import Authentication.Essentials
import Radix exposing (Model)
import Round
import Routing
import String.Ext as String
import Url



-- 🛠


base : { presentable : Bool } -> Model -> String
base { presentable } model =
    model.route
        |> Routing.treePathSegments
        -- TODO: Add domain/host
        -- |> (::)
        --     (if presentable then
        --         foundation.unresolved
        --
        --      else
        --         foundation.resolved
        --     )
        |> List.map Url.percentEncode
        |> String.join "/"
        |> (if presentable then
                model.url
                    |> (\u -> { u | path = "", query = Nothing, fragment = Nothing })
                    |> Url.toString
                    |> String.chopEnd "/"
                    |> String.addSuffix "/#/"
                    |> String.append

            else
                String.append "https://ipfs.runfission.com/ipfs/"
           )


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
