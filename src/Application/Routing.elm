module Routing exposing (..)

import Mode exposing (Mode)
import RemoteData
import String.Ext as String
import Url exposing (Url)
import Url.Parser as Url exposing (..)



-- 🧩


type Route
    = Undecided
      --
    | Explore
      -----------------------------------------
      -- Tree
      -----------------------------------------
    | PersonalTree (List String)
    | Tree { root : String } (List String)



-- 🛠


routeFromUrl : Mode -> Url -> Route
routeFromUrl mode url =
    case mode of
        Mode.Default ->
            case basePath url of
                "" ->
                    Undecided

                "explore/ipfs" ->
                    Explore

                -----------------------------------------
                -- Tree
                -----------------------------------------
                path ->
                    let
                        pathSegments =
                            path
                                |> String.chop "/"
                                |> String.split "/"
                    in
                    case pathSegments of
                        root :: rest ->
                            Tree { root = root } rest

                        [] ->
                            Undecided

        Mode.PersonalDomain ->
            case basePath url of
                "" ->
                    Undecided

                -----------------------------------------
                -- Tree
                -----------------------------------------
                path ->
                    path
                        |> String.chop "/"
                        |> String.split "/"
                        |> PersonalTree


adjustUrl : Url -> Route -> Url
adjustUrl url route =
    case route of
        Undecided ->
            { url | fragment = Nothing }

        --
        Explore ->
            { url | fragment = Just "/explore/ipfs" }

        -----------------------------------------
        -- Tree
        -----------------------------------------
        PersonalTree pathSegments ->
            { url | fragment = Just ("/" ++ String.join "/" pathSegments) }

        Tree { root } pathSegments ->
            let
                frag =
                    case pathSegments of
                        [] ->
                            "/" ++ root

                        _ ->
                            "/" ++ root ++ "/" ++ String.join "/" pathSegments
            in
            { url | fragment = Just frag }


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
        PersonalTree pathSegments ->
            pathSegments

        Tree _ pathSegments ->
            pathSegments

        _ ->
            []


treeRoot : Url -> Route -> Maybe String
treeRoot url route =
    case route of
        PersonalTree _ ->
            case url.host of
                "localhost" ->
                    -- TODO: Remove
                    Just "icidasset-test"

                host ->
                    Just ("files." ++ host)

        Tree { root } _ ->
            Just root

        _ ->
            Nothing


addTreePathSegments : Route -> List String -> Route
addTreePathSegments route segments =
    case route of
        PersonalTree pathSegments ->
            PersonalTree (List.append pathSegments segments)

        Tree properties pathSegments ->
            Tree properties (List.append pathSegments segments)

        _ ->
            route


replaceTreePathSegments : Route -> List String -> Route
replaceTreePathSegments route segments =
    case route of
        PersonalTree _ ->
            PersonalTree segments

        Tree properties _ ->
            Tree properties segments

        _ ->
            route
