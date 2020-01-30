module State.Ipfs exposing (..)

import Ipfs
import Item
import Json.Decode as Json
import Ports
import Return exposing (return)
import Routing
import Types exposing (..)



-- DIRECTORY LIST


getDirectoryListCmd : Model -> Cmd Msg
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


gotDirectoryList : Json.Value -> Model -> ( Model, Cmd Msg )
gotDirectoryList encodedDirList model =
    -- TODO: Error handling
    encodedDirList
        |> Json.decodeValue (Json.list Ipfs.listItemDecoder)
        |> Result.withDefault []
        |> List.map Item.fromIpfs
        |> (\directoryList -> { model | directoryList = Just directoryList })
        |> Return.singleton



-- SETUP


setupCompleted : Model -> ( Model, Cmd Msg )
setupCompleted model =
    return
        { model | ipfs = Ipfs.Ready }
        (case model.rootCid of
            Just _ ->
                getDirectoryListCmd model

            Nothing ->
                Cmd.none
        )
