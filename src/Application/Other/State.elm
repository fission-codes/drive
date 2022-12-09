module Other.State exposing (..)

import Authentication.Essentials as Authentication
import Browser
import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Drive.State as Drive
import FileSystem
import Html.Ext as Html
import Json.Decode as Json
import Keyboard
import Maybe.Extra as Maybe
import Notifications
import Ports
import Radix exposing (..)
import Return exposing (return)
import Return.Extra as Return
import Routing exposing (Route(..))
import Time
import Toasty
import Url exposing (Url)
import Webnative.Error as Webnative
import Webnative.FileSystem
import Webnative.Path as Path
import Webnative.Program



-- 🛠


appUpdateAvailable : Manager
appUpdateAvailable model =
    Return.singleton { model | appUpdate = Installing }


appUpdateFinished : Manager
appUpdateFinished model =
    Return.singleton { model | appUpdate = Installed }


gotInitialisationError : String -> Manager
gotInitialisationError err model =
    Return.singleton
        { model | initialised = Err err }


handleWebnativeError : Webnative.Error -> Manager
handleWebnativeError error model =
    Toasty.addToast
        Notifications.config
        ToastyMsg
        (case error of
            Webnative.InsecureContext ->
                Notifications.text "Drive does not work in a insecure context, maybe switch to HTTPS?"

            Webnative.UnsupportedBrowser ->
                Notifications.text "Drive does not support this browser."

            Webnative.JavascriptError err ->
                Notifications.text err
        )
        (Return.singleton model)


hideWelcomeMessage : Manager
hideWelcomeMessage model =
    model.authenticated
        -- |> Maybe.map (\a -> { a | newUser = False })
        |> (\a -> { model | authenticated = a })
        |> Return.singleton


initialise : Maybe Authentication.Essentials -> Manager
initialise maybeEssentials model =
    let
        route =
            Routing.routeFromUrl maybeEssentials model.url
    in
    Return.singleton
        { model
            | authenticated = maybeEssentials
            , fileSystemStatus =
                if Maybe.isJust maybeEssentials then
                    FileSystem.Loading

                else
                    FileSystem.NotNeeded
            , initialised = Ok True
            , route = route
            , showLoadingOverlay = False
        }


keyboardInteraction : Keyboard.Msg -> Manager
keyboardInteraction msg unmodified =
    (if unmodified.isFocusedOnInput then
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


lostWindowFocus : Manager
lostWindowFocus model =
    Return.singleton { model | pressedKeys = [] }


ready : { fileSystem : Maybe Json.Value, program : Json.Value } -> Manager
ready refs model =
    let
        route =
            model.route

        maybeTreeRoot =
            Routing.treeRoot route

        fileSystemStatus =
            if Maybe.isJust maybeTreeRoot then
                FileSystem.InitialListing

            else
                FileSystem.NotNeeded

        needsRedirect =
            (Routing.isAuthenticatedTree model.authenticated route == False)
                && (List.head (Routing.treePathSegments route) == Just "public")
    in
    return
        -----------------------------------------
        -- Model
        -----------------------------------------
        { model
            | fileSystemRef =
                refs.fileSystem
                    |> Maybe.map (Json.decodeValue Webnative.FileSystem.decoder)
                    |> Maybe.andThen Result.toMaybe
            , fileSystemStatus =
                fileSystemStatus
            , program =
                refs.program
                    |> Json.decodeValue Webnative.Program.decoder
                    |> Result.toMaybe
        }
        -----------------------------------------
        -- Command
        -----------------------------------------
        (case Routing.treePath route of
            Just currentPath ->
                if needsRedirect then
                    -- Needs a redirect when looking at another's public
                    -- folder, and the path starts with `public/`
                    currentPath
                        |> Path.map (List.drop 1)
                        |> Routing.replaceTreePath route
                        |> Routing.routeToUrl model.url
                        |> Url.toString
                        |> Navigation.pushUrl model.navKey

                else if Routing.isAuthenticatedTree model.authenticated route then
                    -- List entire file system for the authenticated user
                    Ports.fsListDirectory
                        { path = Path.encode currentPath }

                else if Maybe.isJust maybeTreeRoot then
                    -- List a public filesystem
                    Ports.fsListPublicDirectory
                        { path =
                            Path.encode currentPath
                        , root =
                            Common.filesDomainFromTreeRoot
                                { usersDomain = model.usersDomain }
                                maybeTreeRoot
                        }

                else
                    Cmd.none

            Nothing ->
                Cmd.none
        )


screenSizeChanged : Int -> Int -> Manager
screenSizeChanged width height model =
    let
        viewportSize =
            { height = height
            , width = width
            }
    in
    Return.singleton
        { model
            | contextMenu = Nothing
            , viewportSize = viewportSize
        }


setCurrentTime : Time.Posix -> Manager
setCurrentTime time model =
    Return.singleton { model | currentTime = time }



-- FOCUS


{-| Some element has lost focus.
-}
blurred : Html.ElementIdentifiers -> Manager
blurred e model =
    if Html.isInputElement e then
        Return.singleton { model | isFocusedOnInput = False }

    else
        Return.singleton model


{-| Some element has received focus.
-}
focused : Html.ElementIdentifiers -> Manager
focused e model =
    if Html.isInputElement e then
        Return.singleton { model | isFocusedOnInput = True }

    else
        Return.singleton model



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
            Routing.routeFromUrl old.authenticated url

        isTreeRoute =
            case route of
                Tree _ _ ->
                    True

                _ ->
                    False

        ( oldRoot, newRoot ) =
            ( Routing.treeRoot old.route
            , Routing.treeRoot route
            )

        isDifferentRoot =
            Maybe.isJust oldRoot && Maybe.isJust newRoot && oldRoot /= newRoot
    in
    { old
        | fileSystemStatus =
            if stillLoading || not isTreeRoute then
                old.fileSystemStatus

            else if isDifferentRoot then
                FileSystem.InitialListing

            else
                FileSystem.AdditionalListing

        --
        , pressedKeys = []
        , route = route
        , url = url
    }
        |> Drive.clearDirectoryListSelection
        |> (\new ->
                if stillLoading || not isTreeRoute then
                    Return.singleton new

                else if isTreeRoute && old.route /= new.route then
                    case Routing.treePath new.route of
                        Just newPath ->
                            if Routing.isAuthenticatedTree new.authenticated new.route then
                                { path = Path.encode newPath }
                                    |> Ports.fsListDirectory
                                    |> return new

                            else
                                { path =
                                    Path.encode newPath
                                , root =
                                    Common.filesDomainFromTreeRoot
                                        { usersDomain = new.usersDomain }
                                        newRoot
                                }
                                    |> Ports.fsListPublicDirectory
                                    |> return new

                        Nothing ->
                            Return.singleton new

                else
                    Return.singleton new
           )
