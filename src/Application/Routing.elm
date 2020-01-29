module Routing exposing (..)

import String.Ext as String
import Url exposing (Url)
import Url.Builder
import Url.Parser as Url exposing (..)



-- 🧩


type Page
    = Drive (List String)
    | NotFound



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
        Drive pathSegments ->
            { url | path = Url.Builder.absolute pathSegments [] }

        NotFound ->
            url



-- 🧹


basePath : Url -> String
basePath { path } =
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


addDrivePathSegments : List String -> Page -> Page
addDrivePathSegments segments page =
    case page of
        Drive pathSegments ->
            segments
                |> List.append pathSegments
                |> Drive

        _ ->
            page
