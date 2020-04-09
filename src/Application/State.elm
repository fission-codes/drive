module State exposing (init, subscriptions, update)

import Authentication.State as Authentication
import Browser.Events as Browser
import Browser.Navigation as Navigation
import Common exposing (defaultDnsLink)
import Common.State as Common
import Debouncer.Messages as Debouncer
import Debouncing
import Drive.ContextMenu
import Drive.Sidebar
import Drive.State as Drive
import Explore.State as Explore
import Ipfs
import Ipfs.State as Ipfs
import Keyboard
import Maybe.Extra as Maybe
import Other.State as Other
import Ports
import RemoteData
import Return
import Routing
import Task
import Time
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        route =
            Routing.routeFromUrl url

        foundation =
            Nothing

        urlCmd =
            case ( flags.foundation, route ) of
                ( Just _, Routing.Tree _ _ ) ->
                    Cmd.none

                ( Just f, _ ) ->
                    Navigation.replaceUrl navKey ("#/" ++ f.unresolved)

                _ ->
                    Cmd.none

        exploreInput =
            foundation
                |> Maybe.map .unresolved
                |> Maybe.orElse (Routing.treeRoot route)
                |> Maybe.withDefault defaultDnsLink
    in
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { authenticated = flags.authenticated
      , currentTime = Time.millisToPosix 0
      , contextMenu = Nothing
      , directoryList = Ok { floor = 1, items = [] }
      , dragndropMode = False
      , exploreInput = Just exploreInput
      , foundation = foundation
      , helpfulNote = Nothing
      , ipfs = Ipfs.Connecting
      , isFocused = False
      , navKey = navKey
      , route = Routing.routeFromUrl url
      , pressedKeys = []
      , viewportSize = flags.viewportSize
      , selectedPath = Nothing
      , showLoadingOverlay = False
      , url = url

      -- Debouncers
      -------------
      , loadingDebouncer = Debouncing.loading.debouncer
      , notificationsDebouncer = Debouncing.notifications.debouncer
      , usernameAvailabilityDebouncer = Debouncing.usernameAvailability.debouncer

      -- Remote Data
      --------------
      , reCreateAccount = RemoteData.NotAsked

      -- Sidebar
      ----------
      , createDirectoryInput = ""
      , expandSidebar = False
      , showPreviewOverlay = False
      , sidebarMode = Drive.Sidebar.defaultMode
      }
      -----------------------------------------
      -- Command
      -----------------------------------------
    , Cmd.batch
        [ Ports.ipfsSetup ()
        , Task.perform SetCurrentTime Time.now
        , urlCmd
        ]
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        Bypass ->
            Return.singleton

        -----------------------------------------
        -- Authentication
        -----------------------------------------
        CheckIfUsernameIsAvailable a ->
            Authentication.checkIfUsernameIsAvailable a

        CreateAccount ->
            Authentication.createAccount

        GotSignUpEmailInput a ->
            Authentication.gotSignUpEmailInput a

        GotSignUpUsernameInput a ->
            Authentication.gotSignUpUsernameInput a

        ReportCreateAccountResult a ->
            Authentication.reportCreateAccountResult a

        ReportUsernameAvailability a ->
            Authentication.reportUsernameAvailability a

        SignIn ->
            Authentication.signIn

        -----------------------------------------
        -- Debouncers
        -----------------------------------------
        LoadingDebouncerMsg a ->
            Debouncer.update update Debouncing.loading.updateConfig a

        NotificationsDebouncerMsg a ->
            Debouncer.update update Debouncing.notifications.updateConfig a

        UsernameAvailabilityDebouncerMsg a ->
            Debouncer.update update Debouncing.usernameAvailability.updateConfig a

        -----------------------------------------
        -- Drive
        -----------------------------------------
        ActivateSidebarMode a ->
            Drive.activateSidebarMode a

        AddFiles a ->
            Drive.addFiles a

        CloseSidebar ->
            Drive.closeSidebar

        CopyPublicUrl a ->
            Drive.copyPublicUrl a

        CopyToClipboard a ->
            Drive.copyToClipboard a

        CreateDirectory ->
            Drive.createDirectory

        DigDeeper a ->
            Drive.digDeeper a

        DownloadItem a ->
            Drive.downloadItem a

        GotCreateDirectoryInput a ->
            Drive.gotCreateDirectoryInput a

        GoUp a ->
            Drive.goUp a

        Select a ->
            Drive.select a

        ShowPreviewOverlay ->
            Drive.showPreviewOverlay

        ToggleExpandedSidebar ->
            Drive.toggleExpandedSidebar

        ToggleSidebarMode a ->
            Drive.toggleSidebarMode a

        -----------------------------------------
        -- Explore
        -----------------------------------------
        ChangeCid ->
            Explore.changeCid

        GotInput a ->
            Explore.gotInput a

        Reset ->
            Explore.reset

        -----------------------------------------
        -- Ipfs
        -----------------------------------------
        GetDirectoryList ->
            Ipfs.getDirectoryList

        GotDirectoryList a ->
            Ipfs.gotDirectoryList a

        GotError a ->
            Ipfs.gotError a

        GotResolvedAddress a ->
            Ipfs.gotResolvedAddress a

        ReplaceResolvedAddress a ->
            Ipfs.replaceResolvedAddress a

        SetupCompleted ->
            Ipfs.setupCompleted

        -----------------------------------------
        -- 🌏 Common
        -----------------------------------------
        HideHelpfulNote ->
            Common.hideHelpfulNote

        RemoveContextMenu ->
            Common.removeContextMenu

        RemoveHelpfulNote ->
            Common.removeHelpfulNote

        ShowContextMenu a b ->
            Common.showContextMenu a b

        ShowHelpfulNote a ->
            Common.showHelpfulNote a

        -----------------------------------------
        -- 🐚 Other
        -----------------------------------------
        Blurred ->
            Other.blurred

        Focused ->
            Other.focused

        GoToRoute a ->
            Other.goToRoute a

        KeyboardInteraction a ->
            Other.keyboardInteraction a

        LinkClicked a ->
            Other.linkClicked a

        ScreenSizeChanged a b ->
            Other.screenSizeChanged a b

        SetCurrentTime a ->
            Other.setCurrentTime a

        ToggleLoadingOverlay a ->
            Other.toggleLoadingOverlay a

        UrlChanged a ->
            Other.urlChanged a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.ipfsCompletedSetup (always SetupCompleted)
        , Ports.ipfsGotDirectoryList GotDirectoryList
        , Ports.ipfsGotError GotError
        , Ports.ipfsGotResolvedAddress GotResolvedAddress
        , Ports.ipfsReplaceResolvedAddress ReplaceResolvedAddress
        , Ports.reportCreateAccountResult ReportCreateAccountResult
        , Ports.reportUsernameAvailability ReportUsernameAvailability

        -- Keep track of which keyboard keys are pressed
        , Sub.map KeyboardInteraction Keyboard.subscriptions

        -- Monitor screen size
        , Browser.onResize ScreenSizeChanged

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime
        ]
