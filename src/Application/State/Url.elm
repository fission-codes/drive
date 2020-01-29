module State.Url exposing (..)

import Browser
import Browser.Navigation as Nav
import Ports
import Return exposing (return)
import Return.Extra as Return exposing (returnWith)
import Routing exposing (Page(..))
import State.Ipfs
import Types exposing (Model, Msg)
import Url exposing (Url)
import Url.Builder



-- 🛠


linkClicked : Browser.UrlRequest -> Model -> ( Model, Cmd Msg )
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            returnWith (Nav.pushUrl model.navKey <| Url.toString url) model

        Browser.External href ->
            returnWith (Nav.load href) model


urlChanged : Url -> Model -> ( Model, Cmd Msg )
urlChanged url oldModel =
    let
        newPage =
            Routing.pageFromUrl url

        newModel =
            { oldModel | page = newPage, url = url }
    in
    return
        newModel
        (if newPage /= oldModel.page then
            State.Ipfs.getDirectoryListCmd newModel

         else
            Cmd.none
        )
