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
    { rootCid : String
    }



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { directoryList : Maybe (List Item)
    , ipfs : Ipfs.State
    , navKey : Nav.Key
    , page : Page
    , rootCid : String
    , url : Url
    }



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      -----------------------------------------
      -- IPFS
      -----------------------------------------
    | IpfsGotDirectoryList Json.Value
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
