module Explore.State exposing (..)

import Browser.Navigation as Navigation
import Explore.Types as Explore exposing (..)
import Ipfs
import Ipfs.State
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Routing
import Types as Root exposing (..)
import Url



-- 📣


update : Explore.Msg -> Root.Manager
update msg =
    case msg of
        Explore ->
            explore

        GotInput a ->
            gotInput a

        Reset ->
            reset



-- 🛠


explore : Root.Manager
explore model =
    case Maybe.unwrap "" String.trim model.exploreInput of
        "" ->
            Return.singleton model

        input ->
            { model | ipfs = Ipfs.Listing, rootCid = Just input }
                |> Return.singleton
                |> Return.effect_ Ipfs.State.getDirectoryListCmd
                |> Return.command (Ports.storeRootCid input)


gotInput : String -> Root.Manager
gotInput input model =
    Return.singleton
        { model
            | ipfs = Ipfs.Ready
            , exploreInput = Just input
            , rootCid = Nothing
        }


reset : Root.Manager
reset model =
    return
        { model
            | directoryList = Ok []
            , exploreInput = Just ""
            , rootCid = Nothing
            , selectedCid = Nothing
        }
        (Cmd.batch
            [ Ports.removeStoredRootCid ()

            --
            , Routing.Blank
                |> Routing.adjustUrl model.url
                |> Url.toString
                |> Navigation.pushUrl model.navKey
            ]
        )
