module Explore.State exposing (..)

import Browser.Navigation as Navigation
import Ipfs
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Routing
import Types exposing (..)
import Url



-- 📣


explore : Manager
explore model =
    case Maybe.unwrap "" String.trim model.exploreInput of
        "" ->
            Return.singleton model

        input ->
            return
                { model
                    | ipfs = Ipfs.InitialListing
                    , foundation = Nothing
                    , isFocused = False
                }
                (Ports.ipfsResolveAddress input)


gotInput : String -> Manager
gotInput input model =
    Return.singleton
        { model
            | ipfs = Ipfs.Ready
            , exploreInput = Just input
            , foundation = Nothing
        }


reset : Manager
reset model =
    return
        { model
            | authenticated = Nothing
            , directoryList = Ok { floor = 1, items = [] }
            , exploreInput = Just ""
            , foundation = Nothing
            , selectedPath = Nothing
        }
        (Cmd.batch
            [ Ports.removeStoredAuthDnsLink ()
            , Ports.removeStoredFoundation ()

            --
            , Routing.Undecided
                |> Routing.adjustUrl model.url
                |> Url.toString
                |> Navigation.pushUrl model.navKey
            ]
        )
