module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Ipfs.State
import Return exposing (return)
import Routing exposing (Page(..))
import Time
import Types as Root
import Url exposing (Url)



-- 🛠


setCurrentTime : Time.Posix -> Root.Manager
setCurrentTime time model =
    Return.singleton { model | currentTime = time }



-- URL


linkClicked : Browser.UrlRequest -> Root.Manager
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            return model (Navigation.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Navigation.load href)


urlChanged : Url -> Root.Manager
urlChanged url old =
    { old | page = Routing.pageFromUrl url, url = url }
        |> Return.singleton
        |> Return.effect_
            (\new ->
                if new.page /= old.page then
                    Ipfs.State.getDirectoryListCmd new

                else
                    Cmd.none
            )
