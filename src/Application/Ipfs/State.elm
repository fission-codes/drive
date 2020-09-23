module Ipfs.State exposing (..)

import Authentication.Essentials
import Browser.Dom as Dom
import Browser.Navigation as Navigation
import Common.State as Common
import Debouncing
import Drive.Item
import Foundation exposing (Foundation)
import Fs.State as Fs
import Ipfs
import Json.Decode as Json
import List.Extra as List
import Maybe.Extra as Maybe
import Mode
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing exposing (Route(..))
import Task
import Types exposing (..)
import Url



-- 🚀
--
-- SETUP


{-| Part Un.

IPFS connection is set up.
This happens at boot time.

Then one of the following scenarios occur:

1.  A foundation is already present (cached), boot file system.
2.  The app has an IPFS address that needs to be resolved.
3.  Do nothing.

-}
setupCompleted : Manager
setupCompleted model =
    case
        ( model.foundation
        , model.authenticated
        )
    of
        ( Just foundation, _ ) ->
            Return.singleton { model | ipfs = Ipfs.InitialListing }
                |> Return.andThen Fs.loadOrList
                |> (if shouldChangeUrl foundation model then
                        Return.command (changeUrl foundation model)

                    else
                        identity
                   )

        ( Nothing, Just essentials ) ->
            if model.route == Explore then
                Return.singleton { model | ipfs = Ipfs.Ready }

            else
                return
                    { model | ipfs = Ipfs.InitialListing }
                    (Ports.ipfsResolveAddress essentials.username)

        ( Nothing, Nothing ) ->
            case Routing.treeRoot model.url model.route of
                Just root ->
                    return
                        { model | ipfs = Ipfs.InitialListing }
                        (Ports.ipfsResolveAddress root)

                Nothing ->
                    Return.singleton { model | ipfs = Ipfs.Ready }


{-| Part Deux.

A foundation has been resolved.
This function can change the URL and stores the foundation in localStorage.

-}
gotResolvedAddress : Foundation -> Manager
gotResolvedAddress foundation model =
    let
        ipfs =
            if shouldChangeUrl foundation model then
                model.ipfs

            else
                Ipfs.InitialListing
    in
    { model | ipfs = ipfs, foundation = Just foundation }
        |> Return.singleton
        |> (if shouldChangeUrl foundation model then
                Return.command (changeUrl foundation model)

            else if Maybe.map .newUser model.authenticated == Just True then
                identity

            else
                -- Otherwise boot up the file system
                Return.andThen Fs.loadOrList
           )
        |> Return.command (Ports.storeFoundation foundation)



-- 🐚
--
-- LIFE


replaceResolvedAddress : { cid : String } -> Manager
replaceResolvedAddress { cid } model =
    case model.foundation of
        Just oldFoundation ->
            let
                newFoundation =
                    { oldFoundation | resolved = cid }
            in
            return
                { model | foundation = Just newFoundation }
                (Ports.storeFoundation newFoundation)

        Nothing ->
            Return.singleton model



-- DIRECTORY LIST
--
-- Regular IPFS.


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

        Ipfs.FileSystemOperation _ ->
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



-- UTILITIES


{-| Do I need to put the ipfs address in the url?
-}
shouldChangeUrl : Foundation -> Model -> Bool
shouldChangeUrl foundation model =
    case model.mode of
        Mode.Default ->
            model.url.fragment
                |> Maybe.withDefault ""
                |> String.startsWith ("/" ++ foundation.unresolved)
                |> not

        Mode.PersonalDomain ->
            False


changeUrl : Foundation -> Model -> Cmd Msg
changeUrl foundation model =
    ("#/" ++ foundation.unresolved)
        |> Navigation.pushUrl model.navKey
