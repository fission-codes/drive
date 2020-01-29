module State.Ipfs exposing (..)

import Ipfs
import Item
import Json.Decode as Json
import Ports
import Return exposing (return)
import Types exposing (..)



-- DIRECTORY LIST


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
        (Ports.ipfsListDirectory model.rootCid)
