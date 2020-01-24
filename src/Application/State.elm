module State exposing (init, subscriptions, update)

import Browser.Navigation as Nav
import Ports
import Return exposing (return)
import State.Url
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { navKey = navKey
      , url = url
      }
      -----------------------------------------
      -- Command
      -----------------------------------------
    , Cmd.none
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        Bypass ->
            Return.singleton

        -----------------------------------------
        -- URL
        -----------------------------------------
        LinkClicked urlRequest ->
            State.Url.linkClicked urlRequest

        UrlChanged url ->
            State.Url.urlChanged url



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
