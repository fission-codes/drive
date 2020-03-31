module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Drive.State as Drive
import FFS.State as FFS
import Ipfs
import Keyboard
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Routing exposing (Route(..))
import Time
import Types exposing (..)
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


toggleLoadingOverlay : { on : Bool } -> Manager
toggleLoadingOverlay { on } model =
    Return.singleton { model | showLoadingOverlay = on }


urlChanged : Url -> Manager
urlChanged url old =
    let
        stillConnecting =
            old.ipfs == Ipfs.Connecting

        route =
            Routing.routeFromUrl url

        isTreeRoute =
            Maybe.isJust (Routing.treeRoot route)

        needsResolve =
            Routing.treeRoot route /= Maybe.map .unresolved old.foundation

        isInitialListing =
            Routing.treeRoot old.route /= Maybe.map .unresolved old.foundation
    in
    { old
        | ipfs =
            if stillConnecting || not isTreeRoute || needsResolve then
                old.ipfs

            else if isInitialListing then
                Ipfs.InitialListing

            else
                Ipfs.AdditionalListing

        --
        , foundation =
            if needsResolve then
                Nothing

            else
                old.foundation

        --
        , route = route
        , selectedPath = Nothing
        , url = url
    }
        |> (\new ->
                if stillConnecting || not isTreeRoute then
                    Return.singleton new

                else if needsResolve then
                    new.route
                        |> Routing.treeRoot
                        |> Maybe.map Ports.ipfsResolveAddress
                        |> Maybe.withDefault Cmd.none
                        |> return new

                else if new.route /= old.route && Maybe.isJust old.foundation then
                    FFS.listDirectory new

                else
                    Return.singleton new
           )
