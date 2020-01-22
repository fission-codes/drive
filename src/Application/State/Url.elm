module State.Url exposing (..)

import Browser
import Browser.Navigation as Nav
import Return exposing (return)
import Types exposing (Model, Msg)
import Url exposing (Url)



-- 🛠


linkClicked : Model -> Browser.UrlRequest -> ( Model, Cmd Msg )
linkClicked model urlRequest =
    case urlRequest of
        Browser.Internal url ->
            return model (Nav.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Nav.load href)


urlChanged : Model -> Url -> ( Model, Cmd Msg )
urlChanged model url =
    Return.singleton { model | url = url }
