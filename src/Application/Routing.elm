module Routing exposing (..)

import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Route
    = Explore
    | Tree { root : String } (List String)
    | Undecided



-- 🛠


routeFromUrl : Url -> Route
routeFromUrl url =
    case basePath url of
        "" ->
            Undecided

        "explore" ->
            Explore

        path ->
            case String.split "/" path of
                root :: rest ->
                    Tree { root = root } rest

                [] ->
                    Undecided


adjustUrl : Url -> Route -> Url
adjustUrl url route =
    case route of
        Explore ->
            { url | fragment = Nothing }

        Tree { root } pathSegments ->
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

        Undecided ->
            { url | fragment = Nothing }



-- 🧹


basePath : Url -> String
basePath url =
    let
        path =
            -- To switch to path-based routing, use url.path
            Maybe.withDefault "" url.fragment
    in
    path
        |> String.chop "/"
        |> String.split "/"
        |> (if String.startsWith "/ipns/" path then
                List.drop 2

            else
                identity
           )
        |> List.map (\s -> Url.percentDecode s |> Maybe.withDefault s)
        |> String.join "/"



-- TREE


treePath : Route -> String
treePath =
    treePathSegments >> String.join "/"


treePathSegments : Route -> List String
treePathSegments route =
    case route of
        Tree _ pathSegments ->
            pathSegments

        _ ->
            []


treeRoot : Route -> Maybe String
treeRoot route =
    case route of
        Tree { root } _ ->
            Just root

        _ ->
            Nothing


addTreePathSegments : Route -> List String -> Route
addTreePathSegments route segments =
    case route of
        Tree properties pathSegments ->
            Tree properties (List.append pathSegments segments)

        _ ->
            route


replaceTreePathSegments : Route -> List String -> Route
replaceTreePathSegments route segments =
    case route of
        Tree properties _ ->
            Tree properties segments

        _ ->
            route
