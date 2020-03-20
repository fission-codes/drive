module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import ContextMenu exposing (ContextMenu)
import Drive.State as Drive
import Html.Events.Extra.Mouse as Mouse
import Ipfs
import Ipfs.State
import Keyboard
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Routing exposing (Route(..))
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🛠


hideContextMenu : Manager
hideContextMenu model =
    Return.singleton { model | contextMenu = Nothing }


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
    Return.singleton { model | contextMenu = Nothing }


setCurrentTime : Time.Posix -> Manager
setCurrentTime time model =
    Return.singleton { model | currentTime = time }


showContextMenu : ContextMenu Msg -> Mouse.Event -> Manager
showContextMenu menu event model =
    let
        menuWithPosition =
            { x = Tuple.first event.clientPos - Tuple.first event.offsetPos + 22
            , y = Tuple.second event.clientPos - Tuple.second event.offsetPos + 40
            }
                |> ContextMenu.position menu
    in
    Return.singleton { model | contextMenu = Just menuWithPosition }



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
        , selectedCid = Nothing
        , url = url
    }
        |> Return.singleton
        |> Return.effect_
            (\new ->
                if stillConnecting || not isTreeRoute then
                    Cmd.none

                else if needsResolve then
                    new.route
                        |> Routing.treeRoot
                        |> Maybe.map Ports.ipfsResolveAddress
                        |> Maybe.withDefault Cmd.none

                else if new.route /= old.route && Maybe.isJust old.foundation then
                    Ipfs.State.getDirectoryListCmd new

                else
                    Cmd.none
            )
