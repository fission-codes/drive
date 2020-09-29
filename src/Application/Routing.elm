module Routing exposing (..)

import Authentication.Essentials as Authentication
import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Route
    = Undecided
    | Tree { root : String } (List String)



-- 🛠


routeFromUrl : Maybe Authentication.Essentials -> Url -> Route
routeFromUrl maybeAuth url =
    case basePath url of
        "" ->
            case maybeAuth of
                Just a ->
                    Tree { root = a.username } []

                Nothing ->
                    Undecided

        -----------------------------------------
        -- Tree
        -----------------------------------------
        path ->
            case String.split "/" (String.chop "/" path) of
                root :: rest ->
                    Tree { root = root } rest

                _ ->
                    Undecided


adjustUrl : Url -> Route -> Url
adjustUrl url route =
    { url | fragment = routeFragment route }


routeFragment : Route -> Maybe String
routeFragment route =
    case route of
        Undecided ->
            Nothing

        Tree { root } pathSegments ->
            Just ("/" ++ String.join "/" (root :: pathSegments))



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
        Tree _ pathSegments ->
            pathSegments

        _ ->
            []


addTreePathSegments : Route -> List String -> Route
addTreePathSegments route segments =
    case route of
        Tree attributes pathSegments ->
            Tree attributes (List.append pathSegments segments)

        _ ->
            route


replaceTreePathSegments : Route -> List String -> Route
replaceTreePathSegments route segments =
    case route of
        Tree attributes _ ->
            Tree attributes segments

        _ ->
            route


treeRoot : Route -> Maybe String
treeRoot route =
    case route of
        Tree { root } _ ->
            Just root

        _ ->
            Nothing


isAuthenticatedTree : Maybe Authentication.Essentials -> Route -> Bool
isAuthenticatedTree auth route =
    case route of
        Tree { root } _ ->
            (String.split "." root |> List.head) == Maybe.map .username auth

        _ ->
            False
