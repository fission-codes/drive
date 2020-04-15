module Explore.State exposing (..)

import Browser.Navigation as Navigation
import Ipfs
import Maybe.Extra as Maybe
import Other.State as Other
import Ports
import Return exposing (andThen, return)
import Routing exposing (Route)
import Types exposing (..)
import Url



-- 📣


changeCid : Manager
changeCid model =
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


reset : Route -> Manager
reset route model =
    [ Ports.removeStoredAuthDnsLink ()
    , Ports.removeStoredFoundation ()
    ]
        |> Cmd.batch
        |> return
            { model
                | authenticated = Nothing
                , directoryList = Ok { floor = 1, items = [] }
                , exploreInput = Just ""
                , foundation = Nothing
                , selectedPath = Nothing
            }
        |> andThen
            (Other.goToRoute route)
