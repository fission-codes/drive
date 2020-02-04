module Types exposing (..)

{-| Root-level types.
-}

import Browser.Navigation as Navigation
import Explore.Types as Explore
import Ipfs
import Ipfs.Types as Ipfs
import Item exposing (Item)
import Management
import Navigation.Types as Navigation
import Routing exposing (Page)
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
    { directoryList : Result String (List Item)
    , exploreInput : Maybe String
    , ipfs : Ipfs.Status
    , navKey : Navigation.Key
    , page : Page
    , rootCid : Maybe String
    , url : Url
    }



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      --
    | ExploreMsg Explore.Msg
    | IpfsMsg Ipfs.Msg
    | NavigationMsg Navigation.Msg


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
