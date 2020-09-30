module Common exposing (..)

import Authentication.Essentials
import Radix exposing (Model)
import Round
import Routing
import String.Ext as String
import Url



-- 🛠


{-| Prefix for public urls.

    Examples:
    - https://drive.fission.codes/#/icidasset/directory/goes/here
    - https://ipfs.runfission.com/ipfs/CID/path/to/file

-}
base : { presentable : Bool } -> Model -> String
base { presentable } model =
    let
        root =
            Maybe.withDefault "" (Routing.treeRoot model.route)
    in
    model.route
        |> Routing.treePathSegments
        |> (\segments ->
                case ( presentable, segments ) of
                    ( False, first :: rest ) ->
                        if first == "public" then
                            "pretty" :: rest

                        else
                            "pretty" :: first :: rest

                    _ ->
                        segments
           )
        |> List.map Url.percentEncode
        |> (::)
            (if presentable then
                root
                    |> filesDomain { usersDomain = model.usersDomain }
                    |> String.chopEnd (".files." ++ model.usersDomain)

             else
                case model.fileSystemCid of
                    Just cid ->
                        cid

                    Nothing ->
                        filesDomain { usersDomain = model.usersDomain } root
            )
        |> String.join "/"
        |> (if presentable then
                model.url
                    |> (\u -> { u | path = "", query = Nothing, fragment = Nothing })
                    |> Url.toString
                    |> String.chopEnd "/"
                    |> String.addSuffix "/#/"
                    |> String.append

            else
                case model.fileSystemCid of
                    Just _ ->
                        String.append "https://ipfs.runfission.com/ipfs/"

                    Nothing ->
                        String.append "https://ipfs.runfission.com/ipns/"
           )


filesDomain : { usersDomain : String } -> String -> String
filesDomain { usersDomain } s =
    if String.contains ".files." s then
        s

    else
        case String.split "." s of
            [] ->
                s

            [ x ] ->
                x ++ ".files." ++ usersDomain

            x :: y ->
                x ++ ".files." ++ String.join "." y


filesDomainFromTreeRoot : { usersDomain : String } -> Maybe String -> String
filesDomainFromTreeRoot attributes maybeTreeRoot =
    case maybeTreeRoot of
        Just treeRoot ->
            filesDomain attributes treeRoot

        Nothing ->
            ""


ifThenElse : Bool -> a -> a -> a
ifThenElse condition x y =
    if condition then
        x

    else
        y


isSingleFileView : Model -> Bool
isSingleFileView model =
    model.selectedPath == Just (Routing.treePath model.route)


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
