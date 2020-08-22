module State exposing (init, subscriptions, update)

import Authentication.Essentials as Authentication
import Browser.Events as Browser
import Browser.Navigation as Navigation
import Common exposing (defaultDnsLink, ifThenElse)
import Common.State as Common
import Debouncer.Messages as Debouncer
import Debouncing
import Drive.Sidebar
import Drive.State as Drive
import Explore.State as Explore
import Fs.State as Fs
import Ipfs
import Ipfs.State as Ipfs
import Keyboard
import Maybe.Extra as Maybe
import Mode
import Notifications
import Other.State as Other
import Ports
import Return
import Routing
import Task
import Time
import Toasty
import Types exposing (..)
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        mode =
            -- if String.endsWith ".fission.name" url.host then
            --     Mode.PersonalDomain
            --
            -- else
            Mode.Default

        route =
            Routing.routeFromUrl mode url

        exploreInput =
            if Maybe.isJust flags.authenticated then
                defaultDnsLink

            else
                flags.foundation
                    |> Maybe.map .unresolved
                    |> Maybe.orElse (Routing.treeRoot url route)
                    |> Maybe.withDefault defaultDnsLink

        loadedFoundation =
            -- TODO: Remove
            flags.foundation
    in
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { authenticated = flags.authenticated
      , currentTime = Time.millisToPosix flags.currentTime
      , contextMenu = Nothing
      , directoryList = Ok { floor = 1, items = [] }
      , dragndropMode = False
      , exploreInput = Just exploreInput
      , foundation = loadedFoundation
      , helpfulNote = Nothing
      , ipfs = Ipfs.Connecting
      , isFocused = False
      , modal = Nothing
      , mode = mode
      , navKey = navKey
      , route = route
      , pressedKeys = []
      , viewportSize = flags.viewportSize
      , selectedPath = Nothing
      , showLoadingOverlay = False
      , toasties = Toasty.initialState
      , url = url
      , usersDomain = flags.usersDomain

      -- Debouncers
      -------------
      , loadingDebouncer = Debouncing.loading.debouncer
      , notificationsDebouncer = Debouncing.notifications.debouncer
      , usernameAvailabilityDebouncer = Debouncing.usernameAvailability.debouncer

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
        ]
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg =
    case msg of
        Bypass ->
            Return.singleton

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

        RemoveItem a ->
            Drive.removeItem a

        RenameItem a ->
            Drive.renameItem a

        Select a ->
            Drive.select a

        ShowPreviewOverlay ->
            Drive.showPreviewOverlay

        ShowRenameItemModal a ->
            Drive.showRenameItemModal a

        ToggleExpandedSidebar ->
            Drive.toggleExpandedSidebar

        ToggleSidebarMode a ->
            Drive.toggleSidebarMode a

        -----------------------------------------
        -- Explore
        -----------------------------------------
        ChangeCid ->
            Explore.changeCid

        GoExplore ->
            Explore.explore

        GotInput a ->
            Explore.gotInput a

        -----------------------------------------
        -- File System
        -----------------------------------------
        GotFsError a ->
            Fs.gotError a

        -----------------------------------------
        -- Ipfs
        -----------------------------------------
        GetDirectoryList ->
            Ipfs.getDirectoryList

        GotDirectoryList a ->
            Ipfs.gotDirectoryList a

        GotIpfsError a ->
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
        GoToRoute a ->
            Common.goToRoute a

        HideHelpfulNote ->
            Common.hideHelpfulNote

        HideModal ->
            Common.hideModal

        RemoveContextMenu ->
            Common.removeContextMenu

        RemoveHelpfulNote ->
            Common.removeHelpfulNote

        Reset a ->
            Common.reset a

        SetModalState a b ->
            Common.setModalState a b

        ShowContextMenu a b ->
            Common.showContextMenu a b

        ShowContextMenuWithCoordinates a b ->
            Common.showContextMenuWithCoordinates a b

        ShowHelpfulNote a ->
            Common.showHelpfulNote a

        -----------------------------------------
        -- 🐚 Other
        -----------------------------------------
        Blurred ->
            Other.blurred

        Focused ->
            Other.focused

        KeyboardInteraction a ->
            Other.keyboardInteraction a

        LinkClicked a ->
            Other.linkClicked a

        RedirectToLobby ->
            Other.redirectToLobby

        ScreenSizeChanged a b ->
            Other.screenSizeChanged a b

        SetCurrentTime a ->
            Other.setCurrentTime a

        ToastyMsg a ->
            Toasty.update Notifications.config ToastyMsg a

        ToggleLoadingOverlay a ->
            Other.toggleLoadingOverlay a

        UrlChanged a ->
            Other.urlChanged a



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.fsGotError GotFsError
        , Ports.ipfsCompletedSetup (always SetupCompleted)
        , Ports.ipfsGotDirectoryList GotDirectoryList
        , Ports.ipfsGotError GotIpfsError
        , Ports.ipfsGotResolvedAddress GotResolvedAddress
        , Ports.ipfsReplaceResolvedAddress ReplaceResolvedAddress

        -- Keep track of which keyboard keys are pressed
        , Sub.map KeyboardInteraction Keyboard.subscriptions

        -- Monitor screen size
        , Browser.onResize ScreenSizeChanged

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime
        ]
