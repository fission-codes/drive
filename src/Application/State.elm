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
import FS.State as FS
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
            flags.foundation
                |> Maybe.map .unresolved
                |> Maybe.orElse (Routing.treeRoot url route)
                |> Maybe.withDefault defaultDnsLink

        loadedFoundation =
            --
            -- When the following is a `Just`,
            -- it will not load from a dnslink and
            -- use the cached cid instead.
            --
            if flags.lastFsOperation + 15 * 60 * 1000 > flags.currentTime then
                -- Last file-system change was only 15 minutes ago, use the cached cid.
                -- This is done because of the delay on DNS updates.
                Maybe.andThen
                    (\{ newUser } -> ifThenElse newUser Nothing flags.foundation)
                    flags.authenticated

            else
                Nothing
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
        , urlCmd flags mode navKey route url
        ]
    )


urlCmd flags mode navKey route url =
    -- Scenarios:
    --
    -- 1. When authenticating, make sure the correct foundation is in place.
    -- 2. When a foundation is present, but we're not at the
    --    correct url, then change the url.
    --
    case ( flags.authenticated, flags.foundation, route ) of
        ( Just { username }, _, _ ) ->
            case mode of
                Mode.Default ->
                    case url.fragment of
                        Just frag ->
                            if String.startsWith ("/" ++ username) frag then
                                Cmd.none

                            else
                                username
                                    |> String.append "#/"
                                    |> Navigation.replaceUrl navKey

                        Nothing ->
                            username
                                |> String.append "#/"
                                |> Navigation.replaceUrl navKey

                Mode.PersonalDomain ->
                    Cmd.none

        ( Nothing, Just _, Routing.Tree _ _ ) ->
            Cmd.none

        ( Nothing, Just f, _ ) ->
            case mode of
                Mode.Default ->
                    Navigation.replaceUrl navKey ("#/" ++ f.unresolved)

                Mode.PersonalDomain ->
                    Cmd.none

        _ ->
            Cmd.none



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

        GotInput a ->
            Explore.gotInput a

        Reset a ->
            Explore.reset a

        -----------------------------------------
        -- File System
        -----------------------------------------
        GotFsError a ->
            FS.gotError a

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
        HideHelpfulNote ->
            Common.hideHelpfulNote

        HideModal ->
            Common.hideModal

        RemoveContextMenu ->
            Common.removeContextMenu

        RemoveHelpfulNote ->
            Common.removeHelpfulNote

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

        GoToRoute a ->
            Other.goToRoute a

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
