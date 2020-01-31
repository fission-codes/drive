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
    encodedDirList
        |> Json.decodeValue (Json.list Ipfs.listItemDecoder)
        |> Result.map (List.map Item.fromIpfs)
        |> Result.mapError Json.errorToString
        |> (\result -> { model | directoryList = result, ipfs = Ipfs.Ready })
        |> Return.singleton



-- ERRORS


gotError : String -> Model -> ( Model, Cmd Msg )
gotError error model =
    Return.singleton
        { model
            | exploreInput = Maybe.withDefault "" model.rootCid
            , ipfs = Ipfs.Error error
        }



-- SETUP


setupCompleted : Model -> ( Model, Cmd Msg )
setupCompleted model =
    case model.rootCid of
        Just _ ->
            return { model | ipfs = Ipfs.Listing } (getDirectoryListCmd model)

        Nothing ->
            Return.singleton { model | ipfs = Ipfs.Ready }
