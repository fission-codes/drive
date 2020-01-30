module State.Explore exposing (..)

import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import State.Ipfs
import Types exposing (..)



-- 🛠


explore : Model -> ( Model, Cmd Msg )
explore model =
    let
        input =
            Maybe.unwrap "" String.trim model.exploreInput
    in
    { model | rootCid = Just input }
        |> Return.singleton
        |> Return.effect_ State.Ipfs.getDirectoryListCmd
        |> Return.command (Ports.storeRootCid input)


gotExploreInput : String -> Model -> ( Model, Cmd Msg )
gotExploreInput input model =
    Return.singleton { model | exploreInput = Just input }


reset : Model -> ( Model, Cmd Msg )
reset model =
    return
        { model
            | directoryList = Nothing
            , exploreInput = Just ""
            , rootCid = Nothing
        }
        (Ports.removeStoredRootCid ())
