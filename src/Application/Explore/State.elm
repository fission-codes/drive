module Explore.State exposing (..)

import Common
import Drive.Sidebar
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
                    , sidebarMode = Drive.Sidebar.defaultMode
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
    [ Ports.annihilateKeys ()
    , Ports.deauthenticate ()
    , Ports.removeStoredFoundation ()
    ]
        |> Cmd.batch
        |> return
            { model
                | directoryList = Ok { floor = 1, items = [] }
                , exploreInput = Just Common.defaultDnsLink
                , foundation = Nothing
                , selectedPath = Nothing
            }
        |> andThen
            (Other.goToRoute route)
