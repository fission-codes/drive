module State.Url exposing (..)

import Browser
import Browser.Navigation as Nav
import Return exposing (return)
import Return.Extra as Return exposing (returnWith)
import Types exposing (Model, Msg)
import Url exposing (Url)



-- 🛠


linkClicked : Browser.UrlRequest -> Model -> ( Model, Cmd Msg )
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            returnWith (Nav.pushUrl model.navKey <| Url.toString url) model

        Browser.External href ->
            returnWith (Nav.load href) model


urlChanged : Url -> Model -> ( Model, Cmd Msg )
urlChanged url model =
    Return.singleton { model | url = url }
