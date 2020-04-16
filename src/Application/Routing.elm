module Routing exposing (..)

import Authentication.Types as Authentication
import RemoteData
import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Route
    = CreateAccount Authentication.SignUpContext
    | Explore
    | LinkAccount
    | Tree { root : String } (List String)
    | Undecided



-- 🏔


createAccount : Route
createAccount =
    CreateAccount
        { email = ""
        , username = ""
        , usernameIsAvailable = RemoteData.NotAsked
        , usernameIsValid = True
        }



-- 🛠


routeFromUrl : Url -> Route
routeFromUrl url =
    case basePath url of
        "" ->
            Undecided

        "account/create" ->
            createAccount

        "account/link" ->
            LinkAccount

        "explore/ipfs" ->
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
        CreateAccount _ ->
            { url | fragment = Just "/account/create" }

        Explore ->
            { url | fragment = Just "/explore/ipfs" }

        LinkAccount ->
            { url | fragment = Just "/account/link" }

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


routeUrl : Route -> Url -> String
routeUrl route originalUrl =
    route
        |> adjustUrl originalUrl
        |> Url.toString



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
