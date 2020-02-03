module Navigation.Types exposing (..)

import Browser
import Url exposing (Url)



-- 📣


type Msg
    = DigDeeper String
    | GoUp { floor : Int }
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url
