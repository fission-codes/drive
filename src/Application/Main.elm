module Main exposing (main)

import Browser
import Radix exposing (..)
import State exposing (init, subscriptions, update)
import View exposing (view)



-- ⛩


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
