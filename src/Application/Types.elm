module Types exposing (..)

{-| Root-level types.
-}

import Browser
import Browser.Navigation as Nav
import Ipfs
import Item exposing (Item)
import Json.Decode as Json
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
      -- URL
      -----------------------------------------
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url



-- 🧩
--
-- Nothing here yet.
-- Here go the other types.
