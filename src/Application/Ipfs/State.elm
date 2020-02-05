module Ipfs.State exposing (..)

import Browser.Dom as Dom
import Ipfs
import Ipfs.Types as Ipfs exposing (..)
import Item
import Json.Decode as Json
import Ports
import Return exposing (return)
import Routing
import Task
import Types as Root exposing (..)



-- 📣


update : Ipfs.Msg -> Root.Manager
update msg =
    case msg of
        GotDirectoryList a ->
            gotDirectoryList a

        GotError a ->
            gotError a

        SetupCompleted ->
            setupCompleted



-- DIRECTORY LIST


getDirectoryListCmd : Root.Model -> Cmd Root.Msg
getDirectoryListCmd model =
    model.page
        |> Routing.drivePathSegments
        |> (case model.rootCid of
                Just rootCid ->
                    (::) rootCid

                Nothing ->
                    identity
           )
        |> String.join "/"
        |> Ports.ipfsListDirectory


gotDirectoryList : Json.Value -> Root.Manager
gotDirectoryList encodedDirList model =
    encodedDirList
        |> Json.decodeValue (Json.list Ipfs.listItemDecoder)
        |> Result.map (List.map Item.fromIpfs)
        |> Result.mapError Json.errorToString
        |> (\result -> { model | directoryList = result, ipfs = Ipfs.Ready })
        |> Return.singleton
        |> Return.command
            (Task.attempt
                (always Bypass)
                (Dom.setViewportOf "drive-items" 0 0)
            )



-- ERRORS


gotError : String -> Root.Manager
gotError error model =
    Return.singleton
        { model
            | exploreInput = model.rootCid
            , ipfs = Ipfs.Error error
        }



-- SETUP


setupCompleted : Root.Manager
setupCompleted model =
    case model.rootCid of
        Just _ ->
            return { model | ipfs = Ipfs.Listing } (getDirectoryListCmd model)

        Nothing ->
            Return.singleton { model | ipfs = Ipfs.Ready }
