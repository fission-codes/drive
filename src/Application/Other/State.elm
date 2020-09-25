module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Drive.State as Drive
import FileSystem
import Keyboard
import Maybe.Extra as Maybe
import Ports
import Radix exposing (..)
import Return exposing (return)
import Return.Extra as Return
import Routing exposing (Route(..))
import Time
import Url exposing (Url)



-- 🛠


keyboardInteraction : Keyboard.Msg -> Manager
keyboardInteraction msg unmodified =
    (if unmodified.isFocused then
        []

     else
        Keyboard.update msg unmodified.pressedKeys
    )
        |> (\p ->
                { unmodified | pressedKeys = p }
           )
        |> (\m ->
                case m.pressedKeys of
                    [ Keyboard.ArrowDown ] ->
                        Drive.selectNextItem m

                    [ Keyboard.ArrowUp ] ->
                        Drive.selectPreviousItem m

                    [ Keyboard.Character "T" ] ->
                        Drive.toggleExpandedSidebar m

                    [ Keyboard.Character "U" ] ->
                        Drive.goUpOneLevel m

                    [ Keyboard.Enter ] ->
                        Drive.digDeeperUsingSelection m

                    [ Keyboard.Escape ] ->
                        Drive.closeSidebar m

                    _ ->
                        Return.singleton m
           )


screenSizeChanged : Int -> Int -> Manager
screenSizeChanged width height model =
    let
        viewportSize =
            { height = height
            , width = width
            }
    in
    Return.singleton { model | contextMenu = Nothing, viewportSize = viewportSize }


setCurrentTime : Time.Posix -> Manager
setCurrentTime time model =
    Return.singleton { model | currentTime = time }



-- FOCUS


{-| Some element has lost focus.
-}
blurred : Manager
blurred model =
    Return.singleton { model | isFocused = False }


{-| Some element has received focus.
-}
focused : Manager
focused model =
    Return.singleton { model | isFocused = True }



-- URL


linkClicked : Browser.UrlRequest -> Manager
linkClicked urlRequest model =
    case urlRequest of
        Browser.Internal url ->
            return model (Navigation.pushUrl model.navKey <| Url.toString url)

        Browser.External href ->
            return model (Navigation.load href)


redirectToLobby : Manager
redirectToLobby =
    Return.communicate (Ports.redirectToLobby ())


toggleLoadingOverlay : { on : Bool } -> Manager
toggleLoadingOverlay { on } model =
    Return.singleton { model | showLoadingOverlay = on }


{-| This function is responsible for changing the application state based on the URL.
-}
urlChanged : Url -> Manager
urlChanged url old =
    let
        stillLoading =
            old.fileSystemStatus == FileSystem.Loading

        route =
            Routing.routeFromUrl (Maybe.isJust old.authenticated) url

        isTreeRoute =
            case route of
                Tree _ ->
                    True

                _ ->
                    False
    in
    { old
        | fileSystemStatus =
            if stillLoading || not isTreeRoute then
                old.fileSystemStatus

            else
                FileSystem.AdditionalListing

        --
        , route = route
        , selectedPath = Nothing
        , url = url
    }
        |> (\new ->
                if stillLoading || not isTreeRoute then
                    Return.singleton new

                else if isTreeRoute && old.route /= new.route then
                    { pathSegments = Routing.treePathSegments route }
                        |> Ports.fsListDirectory
                        |> return new

                else
                    Return.singleton new
           )
