module State exposing (init, subscriptions, update)

import Browser.Events as Browser
import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Debouncer.Messages as Debouncer
import Debouncing
import Drive.Item.Inventory
import Drive.State as Drive
import FileSystem
import FileSystem.State as FileSystem
import Keyboard
import Notifications
import Other.State as Other
import Ports
import Radix exposing (..)
import Return
import Routing
import Task
import Time
import Toasty
import Url exposing (Url)



-- 🌱


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( -----------------------------------------
      -- Model
      -----------------------------------------
      { authenticated = Nothing
      , currentTime = Time.millisToPosix flags.currentTime
      , contextMenu = Nothing
      , directoryList = Ok Drive.Item.Inventory.default
      , dragndropMode = False
      , fileSystemCid = Nothing
      , fileSystemStatus = FileSystem.Ready
      , helpfulNote = Nothing
      , isFocused = False
      , modal = Nothing
      , navKey = navKey
      , route = Routing.Undecided
      , pressedKeys = []
      , viewportSize = flags.viewportSize
      , showLoadingOverlay = True
      , toasties = Toasty.initialState
      , url = url
      , usersDomain = flags.usersDomain

      -- Debouncers
      -------------
      , loadingDebouncer = Debouncing.loading.debouncer
      , notificationsDebouncer = Debouncing.notifications.debouncer

      -- Sidebar
      ----------
      , sidebarExpanded = False
      , sidebar = Nothing
      }
      -----------------------------------------
      -- Command
      -----------------------------------------
    , Task.perform SetCurrentTime Time.now
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

        -----------------------------------------
        -- Drive
        -----------------------------------------
        ActivateSidebarAddOrCreate ->
            Drive.activateSidebarAddOrCreate

        AddFiles a ->
            Drive.addFiles a

        ClearSelection ->
            Drive.clearSelection

        CloseSidebar ->
            Drive.closeSidebar

        CopyPublicUrl a ->
            Drive.copyPublicUrl a

        CopyToClipboard a ->
            Drive.copyToClipboard a

        DigDeeper a ->
            Drive.digDeeper a

        DownloadItem a ->
            Drive.downloadItem a

        GotAddOrCreateInput a ->
            Drive.gotAddCreateInput a

        CreateFileOrFolder a ->
            Drive.createFileOrFolder a

        GoUp a ->
            Drive.goUp a

        IndividualSelect a b ->
            Drive.individualSelect a b

        RangeSelect a b ->
            Drive.rangeSelect a b

        RemoveItem a ->
            Drive.removeItem a

        RemoveSelectedItems ->
            Drive.removeSelectedItems

        RenameItem a ->
            Drive.renameItem a

        Select a b ->
            Drive.select a b

        ShowRenameItemModal a ->
            Drive.showRenameItemModal a

        ToggleExpandedSidebar ->
            Drive.toggleExpandedSidebar

        ToggleSidebarAddOrCreate ->
            Drive.toggleSidebarAddOrCreate

        SidebarMsg sidebarMsg ->
            Drive.updateSidebar sidebarMsg

        -----------------------------------------
        -- File System
        -----------------------------------------
        GotFsDirectoryList a ->
            FileSystem.gotDirectoryList a

        GotFsError a ->
            FileSystem.gotError a

        GotFsItemUtf8 a ->
            FileSystem.gotItemUtf8 a

        -----------------------------------------
        -- Webnative-Elm
        -----------------------------------------
        GotWebnativeResponse a ->
            Drive.gotWebnativeResponse a

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

        HideWelcomeMessage ->
            Other.hideWelcomeMessage

        Initialise a ->
            Other.initialise a

        KeyboardInteraction a ->
            Other.keyboardInteraction a

        LinkClicked a ->
            Other.linkClicked a

        LostWindowFocus ->
            Other.lostWindowFocus

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
        [ Ports.fsGotDirectoryList GotFsDirectoryList
        , Ports.fsGotItemUtf8 GotFsItemUtf8
        , Ports.fsGotError GotFsError
        , Ports.initialise Initialise
        , Ports.lostWindowFocus (always LostWindowFocus)

        -- Keep track of which keyboard keys are pressed
        , Sub.map KeyboardInteraction Keyboard.subscriptions

        -- Monitor screen size
        , Browser.onResize ScreenSizeChanged

        -- Check every 30 seconds what the current time is
        , Time.every (30 * 1000) SetCurrentTime

        -- Setup webnative
        , Ports.webnativeResponse GotWebnativeResponse
        ]
