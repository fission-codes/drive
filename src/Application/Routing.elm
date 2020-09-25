module Routing exposing (..)

import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Route
    = Undecided
    | Tree (List String)



-- 🛠


routeFromUrl : Bool -> Url -> Route
routeFromUrl isAuthenticated url =
    case basePath url of
        "" ->
            if isAuthenticated then
                Tree []

            else
                Undecided

        -----------------------------------------
        -- Tree
        -----------------------------------------
        path ->
            path
                |> String.chop "/"
                |> String.split "/"
                |> Tree


adjustUrl : Url -> Route -> Url
adjustUrl url route =
    case route of
        Undecided ->
            { url | fragment = Nothing }

        Tree pathSegments ->
            { url | fragment = Just ("/" ++ String.join "/" pathSegments) }


routeUrl : Route -> Url -> String
routeUrl route originalUrl =
    route
        |> adjustUrl originalUrl
        |> Url.toString


routeUrlF : Url -> Route -> String
routeUrlF originalUrl route =
    routeUrl route originalUrl



-- 🧹


basePath : Url -> String
basePath url =
    let
        path =
            Maybe.withDefault "" url.fragment
    in
    path
        |> String.chop "/"
        |> String.split "/"
        |> List.map (\s -> Url.percentDecode s |> Maybe.withDefault s)
        |> String.join "/"



-- TREE


treePath : Route -> String
treePath =
    treePathSegments >> String.join "/"


treePathSegments : Route -> List String
treePathSegments route =
    case route of
        Tree pathSegments ->
            pathSegments

        _ ->
            []


addTreePathSegments : Route -> List String -> Route
addTreePathSegments route segments =
    case route of
        Tree pathSegments ->
            Tree (List.append pathSegments segments)

        _ ->
            route


replaceTreePathSegments : Route -> List String -> Route
replaceTreePathSegments route segments =
    case route of
        Tree _ ->
            Tree segments

        _ ->
            route
