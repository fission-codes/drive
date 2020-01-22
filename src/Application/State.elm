module State exposing (init, subscriptions, update)

import Browser.Navigation as Nav
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
update msg model =
    case msg of
        Bypass ->
            ( model, Cmd.none )

        -----------------------------------------
        -- URL
        -----------------------------------------
        LinkClicked urlRequest ->
            State.Url.linkClicked model urlRequest

        UrlChanged url ->
            State.Url.urlChanged model url



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
