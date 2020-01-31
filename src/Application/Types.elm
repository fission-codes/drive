module Types exposing (..)

{-| Root-level types.
-}

import Browser
import Browser.Navigation as Nav
import Ipfs
import Item exposing (Item)
import Json.Decode as Json
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
    , ipfs : Ipfs.State
    , navKey : Nav.Key
    , page : Page
    , rootCid : Maybe String
    , url : Url
    }



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      -----------------------------------------
      -- Explore
      -----------------------------------------
    | Explore
    | GotExploreInput String
    | Reset
      -----------------------------------------
      -- IPFS
      -----------------------------------------
    | IpfsGotDirectoryList Json.Value
    | IpfsGotError String
    | IpfsSetupCompleted
      -----------------------------------------
      -- Traversal
      -----------------------------------------
    | DigDeeper String
    | GoUp { floor : Int }
      -----------------------------------------
      -- URL
      -----------------------------------------
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url



-- 🧩
--
-- Nothing here yet.
-- Here go the other types.
