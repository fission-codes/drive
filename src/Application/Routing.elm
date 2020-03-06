module Routing exposing (..)

import String.Ext as String
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)



-- 🧩


type Page
    = Blank
    | Drive (List String)



-- 🛠


pageFromUrl : Url -> Page
pageFromUrl url =
    case basePath url of
        "" ->
            Drive []

        path ->
            Drive (String.split "/" path)


adjustUrl : Url -> Page -> Url
adjustUrl url page =
    case page of
        Blank ->
            { url | fragment = Nothing }

        Drive pathSegments ->
            -- To switch to path-based routing, use { url | path = ... }
            { url | fragment = Just (Url.Builder.absolute pathSegments []) }



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
        Drive pathSegments ->
            pathSegments

        _ ->
            []
