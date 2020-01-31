module State.Explore exposing (..)

import Ipfs
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import State.Ipfs
import Types exposing (..)



-- 🛠


explore : Model -> ( Model, Cmd Msg )
explore model =
    case String.trim model.exploreInput of
        "" ->
            Return.singleton model

        input ->
            { model | ipfs = Ipfs.Listing, rootCid = Just input }
                |> Return.singleton
                |> Return.effect_ State.Ipfs.getDirectoryListCmd
                |> Return.command (Ports.storeRootCid input)


gotExploreInput : String -> Model -> ( Model, Cmd Msg )
gotExploreInput input model =
    Return.singleton
        { model
            | ipfs = Ipfs.Ready
            , exploreInput = input
            , rootCid = Nothing
        }


reset : Model -> ( Model, Cmd Msg )
reset model =
    return
        { model
            | directoryList = Ok []
            , exploreInput = ""
            , rootCid = Nothing
        }
        (Ports.removeStoredRootCid ())
