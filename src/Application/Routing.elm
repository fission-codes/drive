module Routing exposing (..)

import String.Ext as String
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)



-- 🧩


type Page
    = Blank
    | Drive { root : String } (List String)



-- 🛠


pageFromUrl : Url -> Page
pageFromUrl url =
    case basePath url of
        "" ->
            Blank

        path ->
            case String.split "/" path of
                root :: rest ->
                    Drive { root = root } rest

                [] ->
                    Blank


adjustUrl : Url -> Page -> Url
adjustUrl url page =
    case page of
        Blank ->
            { url | fragment = Nothing }

        Drive { root } pathSegments ->
            let
                frag =
                    case pathSegments of
                        [] ->
                            "/" ++ root

                        _ ->
                            "/" ++ root ++ "/" ++ String.join "/" pathSegments
            in
            -- To switch to path-based routing, use { url | path = ... }
            { url | fragment = Just frag }



-- 🧹


basePath : Url -> String
basePath url =
    let
        path =
            -- To switch to path-based routing, use url.path
            Maybe.withDefault "" url.fragment
    in
    if String.startsWith "/ipns/" path then
        path
            |> String.chopStart "/"
            |> String.chopEnd "/"
            |> String.split "/"
            |> List.drop 2
            |> List.map (\s -> Url.percentDecode s |> Maybe.withDefault s)
            |> String.join "/"

    else
        path
            |> String.chopStart "/"
            |> String.chopEnd "/"
            |> String.split "/"
            |> List.map (\s -> Url.percentDecode s |> Maybe.withDefault s)
            |> String.join "/"



-- DRIVE


drivePathSegments : Page -> List String
drivePathSegments page =
    case page of
        Drive _ pathSegments ->
            pathSegments

        _ ->
            []


driveRoot : Page -> Maybe String
driveRoot page =
    case page of
        Drive { root } _ ->
            Just root

        _ ->
            Nothing


addDrivePathSegments : Page -> List String -> Page
addDrivePathSegments page segments =
    case page of
        Drive properties pathSegments ->
            Drive properties (List.append pathSegments segments)

        _ ->
            page


replaceDrivePathSegments : Page -> List String -> Page
replaceDrivePathSegments page segments =
    case page of
        Drive properties _ ->
            Drive properties segments

        _ ->
            page
