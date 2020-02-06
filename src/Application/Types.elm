module Types exposing (..)

{-| Root-level types.
-}

import Browser
import Browser.Navigation as Navigation
import Drive.Types as Drive
import Explore.Types as Explore
import Ipfs
import Ipfs.Types as Ipfs
import Item exposing (Item)
import Management
import Routing exposing (Page)
import Time
import Url exposing (Url)



-- ⛩


{-| Flags passed initializing the application.
-}
type alias Flags =
    { rootCid : Maybe String
    }



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { currentTime : Time.Posix
    , directoryList : Result String (List Item)
    , exploreInput : Maybe String
    , ipfs : Ipfs.Status
    , largePreview : Bool
    , navKey : Navigation.Key
    , page : Page
    , rootCid : Maybe String
    , selectedCid : Maybe String
    , url : Url
    }



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      -----------------------------------------
      -- Bits
      -----------------------------------------
    | DriveMsg Drive.Msg
    | ExploreMsg Explore.Msg
    | IpfsMsg Ipfs.Msg
      -----------------------------------------
      -- Other
      -----------------------------------------
    | LinkClicked Browser.UrlRequest
    | SetCurrentTime Time.Posix
    | UrlChanged Url


{-| State management.
-}
type alias Organizer model =
    Management.Manager Msg model


type alias Manager =
    Organizer Model



-- 🧩
--
-- Nothing here yet.
-- Here go the other types.
