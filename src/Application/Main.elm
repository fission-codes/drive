module Main exposing (main)

import Browser
import Navigation.Types as Navigation
import State exposing (init, subscriptions, update)
import Types exposing (..)
import View exposing (view)



-- ⛩


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = NavigationMsg << Navigation.UrlChanged
        , onUrlRequest = NavigationMsg << Navigation.LinkClicked
        }
