module Types exposing (..)

{-| Root-level types.
-}

import Browser
import Browser.Navigation as Nav
import Url exposing (Url)



-- ⛩


{-| Flags passed initializing the application.
-}
type alias Flags =
    {}



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { navKey : Nav.Key
    , url : Url
    }



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      -----------------------------------------
      -- URL
      -----------------------------------------
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url



-- 🧩
--
-- Nothing here yet.
-- Here go the other types.
