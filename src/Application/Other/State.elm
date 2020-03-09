module Other.State exposing (..)

import Browser
import Browser.Navigation as Navigation
import Drive.State as Drive
import Ipfs
import Ipfs.State
import Keyboard
import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Routing exposing (Page(..))
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🛠


keyboardInteraction : Keyboard.Msg -> Manager
keyboardInteraction msg unmodified =
    (\m ->
        case m.pressedKeys of
            [ Keyboard.ArrowDown ] ->
                Drive.selectNextItem m

            [ Keyboard.ArrowUp ] ->
                Drive.selectPreviousItem m

            [ Keyboard.Character "T" ] ->
                Drive.toggleLargePreview m

            [ Keyboard.Character "U" ] ->
                Drive.goUpOneLevel m

            [ Keyboard.Enter ] ->
                Drive.digDeeperUsingSelection m

            [ Keyboard.Escape ] ->
                Drive.removeSelection m

            _ ->
                Return.singleton m
    )
        { unmodified | pressedKeys = Keyboard.update msg unmodified.pressedKeys }


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
    let
        page =
            Routing.pageFromUrl url

        isNotDrivePage =
            Maybe.isNothing (Routing.driveRoot page)

        needsResolve =
            Routing.driveRoot page /= Maybe.map .unresolved old.roots

        isInitialListing =
            Routing.driveRoot old.page /= Maybe.map .unresolved old.roots
    in
    { old
        | ipfs =
            if isNotDrivePage || needsResolve then
                old.ipfs

            else if isInitialListing then
                Ipfs.InitialListing

            else
                Ipfs.AdditionalListing

        --
        , roots =
            if needsResolve then
                Nothing

            else
                old.roots

        --
        , page = page
        , selectedCid = Nothing
        , url = url
    }
        |> Return.singleton
        |> Return.effect_
            (\new ->
                if isNotDrivePage then
                    Cmd.none

                else if needsResolve then
                    new.page
                        |> Routing.driveRoot
                        |> Maybe.map Ports.ipfsResolveAddress
                        |> Maybe.withDefault Cmd.none

                else if new.page /= old.page && Maybe.isJust old.roots then
                    Ipfs.State.getDirectoryListCmd new

                else
                    Cmd.none
            )
