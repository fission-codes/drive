module Routing exposing (..)

import Authentication.Essentials as Authentication
import Maybe.Extra as Maybe
import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)
import Webnative.Path as Path exposing (Directory, Encapsulated, Path)
import Webnative.Path.Encapsulated as Path
import Webnative.Path.Extra as Path



-- 🧩


type Route
    = Undecided
    | Tree { root : String } (Path Encapsulated)



-- 🛠


routeFromUrl : Maybe Authentication.Essentials -> Url -> Route
routeFromUrl maybeAuth url =
    case basePath url of
        "" ->
            case maybeAuth of
                Just a ->
                    treeRootTopLevel a.username

                Nothing ->
                    Undecided

        -----------------------------------------
        -- Tree
        -----------------------------------------
        path ->
            case Path.uncons (Path.fromPosix path) of
                Just ( username, remainingPath ) ->
                    Tree { root = username } remainingPath

                Nothing ->
                    Undecided


routeToUrl : Url -> Route -> Url
routeToUrl url route =
    { url | fragment = Just (toString route) }


toString : Route -> String
toString route =
    case route of
        Undecided ->
            "/"

        Tree { root } path ->
            path
                |> Path.map ((::) root)
                |> Path.toPosix
                |> (\p ->
                        if p == "/" then
                            p

                        else
                            "/" ++ p
                   )



-- 🧹


basePath : Url -> String
basePath url =
    url.fragment
        |> Maybe.withDefault ""
        |> String.chopStart "/"
        |> (\s -> Url.percentDecode s |> Maybe.withDefault s)



-- TREE


treePath : Route -> Maybe (Path Encapsulated)
treePath route =
    case route of
        Tree _ path ->
            Just path

        _ ->
            Nothing


treeDirectory : Route -> Maybe (Path Directory)
treeDirectory =
    treePath >> Maybe.andThen Path.toDirectory


treePathSegments : Route -> List String
treePathSegments =
    treePath >> Maybe.unwrap [] Path.unwrap


replaceTreePath : Route -> Path Encapsulated -> Route
replaceTreePath route path =
    case route of
        Tree attributes _ ->
            Tree attributes path

        _ ->
            route


treeRoot : Route -> Maybe String
treeRoot route =
    case route of
        Tree { root } _ ->
            Just root

        _ ->
            Nothing


treeRootTopLevel : String -> Route
treeRootTopLevel root =
    Tree { root = root } (Path.encapsulate Path.root)


isAuthenticatedTree : Maybe Authentication.Essentials -> Route -> Bool
isAuthenticatedTree auth route =
    case route of
        Tree { root } _ ->
            (String.split "." root |> List.head) == Maybe.map .username auth

        _ ->
            False
