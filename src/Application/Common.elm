module Common exposing (..)

import Authentication.Essentials
import Round
import Routing
import String.Ext as String
import Types exposing (Model)
import Url



-- 🛠


base : { presentable : Bool } -> Model -> String
base { presentable } model =
    case model.foundation of
        Just foundation ->
            model.route
                |> Routing.treePathSegments
                |> (::)
                    (if presentable then
                        foundation.unresolved

                     else
                        foundation.resolved
                    )
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

        Nothing ->
            ""


defaultDnsLink : String
defaultDnsLink =
    "boris.fission.name"


ifThenElse : Bool -> a -> a -> a
ifThenElse condition x y =
    if condition then
        x

    else
        y


isAuthenticatedAndNotExploring : Model -> Bool
isAuthenticatedAndNotExploring model =
    case ( model.authenticated, model.foundation ) of
        ( Just essentials, Just { unresolved } ) ->
            Authentication.Essentials.dnsLink model.usersDomain essentials == unresolved

        _ ->
            False


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
