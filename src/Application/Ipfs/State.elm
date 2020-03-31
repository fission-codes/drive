module Ipfs.State exposing (..)

import Browser.Dom as Dom
import Browser.Navigation as Navigation
import Common.State as Common
import Debouncing
import Drive.Item
import FFS.State as FFS
import Ipfs
import Json.Decode as Json
import List.Extra as List
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing exposing (Route(..))
import Task
import Types exposing (..)



-- DIRECTORY LIST


getDirectoryList : Manager
getDirectoryList model =
    return model (getDirectoryListCmd model)


getDirectoryListCmd : Model -> Cmd Msg
getDirectoryListCmd model =
    let
        pathSegments =
            Routing.treePathSegments model.route

        address =
            pathSegments
                |> (case model.foundation of
                        Just { resolved } ->
                            (::) resolved

                        Nothing ->
                            identity
                   )
                |> String.join "/"
    in
    Ports.ipfsListDirectory
        { address = address
        , pathSegments = pathSegments
        }


gotDirectoryList : Json.Value -> Manager
gotDirectoryList encodedFeedback model =
    let
        pathSegments =
            encodedFeedback
                |> Json.decodeValue
                    (Json.field "pathSegments" <| Json.list Json.string)
                |> Result.withDefault
                    []

        encodedDirList =
            encodedFeedback
                |> Json.decodeValue
                    (Json.field "results" Json.value)
                |> Result.withDefault
                    encodedFeedback
    in
    case model.ipfs of
        Ipfs.InitialListing ->
            gotDirectoryList_ pathSegments encodedDirList model

        Ipfs.FileSystemOperation ->
            gotDirectoryList_ pathSegments encodedDirList model

        Ipfs.AdditionalListing ->
            if Routing.treePathSegments model.route == pathSegments then
                gotDirectoryList_ pathSegments encodedDirList model

            else
                Return.singleton model

        _ ->
            Return.singleton model


gotDirectoryList_ : List String -> Json.Value -> Manager
gotDirectoryList_ pathSegments encodedDirList model =
    encodedDirList
        |> Json.decodeValue (Json.list Ipfs.listItemDecoder)
        |> Result.map (List.map Drive.Item.fromIpfs)
        |> Result.mapError Json.errorToString
        |> (\result ->
                let
                    floor =
                        List.length pathSegments + 1

                    listResult =
                        Result.map
                            ({ isGroundFloor = floor == 1 }
                                |> Drive.Item.sortingFunction
                                |> List.sortWith
                            )
                            result

                    lastRouteSegment =
                        List.last (Routing.treePathSegments model.route)

                    selectedPath =
                        case listResult of
                            Ok [ singleItem ] ->
                                if Just singleItem.name == lastRouteSegment then
                                    Just singleItem.path

                                else
                                    Nothing

                            _ ->
                                Nothing
                in
                { model
                    | directoryList =
                        Result.map
                            (\items -> { floor = floor, items = items })
                            listResult

                    --
                    , expandSidebar = Maybe.isJust selectedPath
                    , ipfs = Ipfs.Ready
                    , selectedPath = selectedPath
                    , showLoadingOverlay = False
                }
           )
        |> Common.potentiallyRenderMedia
        |> Return.andThen Debouncing.cancelLoading
        |> Return.command
            (Task.attempt
                (always Bypass)
                (Dom.setViewport 0 0)
            )



-- ERRORS


gotError : String -> Manager
gotError error model =
    Return.singleton
        { model
            | exploreInput = Maybe.map .unresolved model.foundation
            , ipfs = Ipfs.Error error
        }



-- SETUP


gotResolvedAddress : Foundation -> Manager
gotResolvedAddress foundation model =
    let
        changeUrl =
            -- Do I need to put the ipfs address in the url?
            model.url.fragment
                |> Maybe.withDefault ""
                |> String.startsWith ("/" ++ foundation.unresolved)
                |> not

        ipfs =
            if changeUrl then
                model.ipfs

            else
                Ipfs.InitialListing
    in
    { model | ipfs = ipfs, foundation = Just foundation }
        |> Return.singleton
        |> (if changeUrl then
                -- If the url needs to change, issue a navigation command
                ("#/" ++ foundation.unresolved)
                    |> Navigation.pushUrl model.navKey
                    |> Return.command

            else
                -- Otherwise boot up the file system
                Return.andThen FFS.boot
           )
        |> Return.command (Ports.storeFoundation foundation)


setupCompleted : Manager
setupCompleted model =
    case model.foundation of
        Just _ ->
            FFS.boot { model | ipfs = Ipfs.InitialListing }

        Nothing ->
            case model.route of
                Tree { root } _ ->
                    return
                        { model | ipfs = Ipfs.InitialListing }
                        (Ports.ipfsResolveAddress root)

                _ ->
                    Return.singleton { model | ipfs = Ipfs.Ready }



-- 🐚


replaceResolvedAddress : { cid : String } -> Manager
replaceResolvedAddress { cid } model =
    case model.foundation of
        Just oldFoundation ->
            let
                newFoundation =
                    { oldFoundation | resolved = cid }
            in
            { model | foundation = Just newFoundation }
                |> FFS.boot
                |> Return.command (Ports.storeFoundation newFoundation)

        Nothing ->
            Return.singleton model
