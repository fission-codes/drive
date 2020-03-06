module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Ipfs
import Ipfs.State
import Maybe.Extra as Maybe
import Return exposing (return)
import Routing exposing (Page(..))
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🛠


setCurrentTime : Time.Posix -> Manager
setCurrentTime time model =
    Return.singleton { model | currentTime = time }



-- URL


linkClicked : Browser.UrlRequest -> Manager
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            return model (Navigation.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Navigation.load href)


toggleLoadingOverlay : { on : Bool } -> Manager
toggleLoadingOverlay { on } model =
    Return.singleton { model | showLoadingOverlay = on }


urlChanged : Url -> Manager
urlChanged url old =
    { old
        | ipfs = Ipfs.AdditionalListing
        , page = Routing.pageFromUrl url
        , selectedCid = Nothing
        , url = url
    }
        |> Return.singleton
        |> Return.effect_
            (\new ->
                if new.page /= old.page && Maybe.isJust old.rootCid then
                    Ipfs.State.getDirectoryListCmd new

                else
                    Cmd.none
            )
