module Radix exposing (..)

{-| Root-level types.
-}

import Authentication.Essentials as Authentication
import Browser
import Browser.Navigation as Navigation
import ContextMenu exposing (ContextMenu)
import Coordinates exposing (Coordinates)
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Drive.Item as Item exposing (Item)
import Drive.Item.Inventory as Item
import Drive.Sidebar
import FileSystem
import Html.Events.Extra.Mouse as Mouse
import Html.Ext as Html
import Json.Decode as Json
import Keyboard
import Management
import Modal exposing (Modal)
import Notifications exposing (Notification)
import Routing exposing (Route)
import Time
import Toasty
import Url exposing (Url)
import Webnative.Error as Webnative
import Webnative.FileSystem exposing (FileSystem)
import Webnative.Program exposing (Program)



-- ⛩


{-| Flags passed initializing the application.
-}
type alias Flags =
    { apiEndpoint : String
    , currentTime : Int
    , usersDomain : String
    , viewportSize : { height : Int, width : Int }
    }



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { apiEndpoint : String
    , appUpdate : AppUpdate
    , authenticated : Maybe Authentication.Essentials
    , contextMenu : Maybe (ContextMenu Msg)
    , currentTime : Time.Posix
    , directoryList : Result String Item.Inventory
    , dragndropMode : Bool
    , fileSystemCid : Maybe String
    , fileSystemRef : Maybe FileSystem
    , fileSystemStatus : FileSystem.Status
    , helpfulNote : Maybe { faded : Bool, note : String }
    , initialised : Result String Bool
    , isFocusedOnInput : Bool
    , modal : Maybe (Modal Msg)
    , navKey : Navigation.Key
    , pressedKeys : List Keyboard.Key
    , program : Maybe Program
    , route : Route
    , showLoadingOverlay : Bool
    , toasties : Toasty.Stack (Notification Msg)
    , url : Url
    , usersDomain : String
    , viewportSize : { height : Int, width : Int }

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , loadingDebouncer : Debouncer Msg
    , notificationsDebouncer : Debouncer Msg
    , usernameLookupDebouncer : Debouncer Msg

    -----------------------------------------
    -- Sidebar
    -----------------------------------------
    , sidebarExpanded : Bool
    , sidebar : Maybe Drive.Sidebar.Model
    }


type AppUpdate
    = NotAvailable
    | Installing
    | Installed



-- 📣


{-| Messages, or actions, that influence our `Model`.
-}
type Msg
    = Bypass
      -----------------------------------------
      -- Debouncers
      -----------------------------------------
    | LoadingDebouncerMsg (Debouncer.Msg Msg)
    | NotificationsDebouncerMsg (Debouncer.Msg Msg)
    | UsernameLookupDebouncerMsg (Debouncer.Msg Msg)
      -----------------------------------------
      -- Drive
      -----------------------------------------
    | ActivateSidebarAddOrCreate
    | AddFiles { blobs : List { path : String, url : String } }
    | ClearSelection
    | CloseSidebar
    | CopyPublicUrl { item : Item, presentable : Bool }
    | CopyToClipboard { clip : String, notification : String }
    | CreateFile
    | CreateFolder
    | DigDeeper { directoryName : String }
    | DownloadItem Item
    | GotAddOrCreateInput String
    | GoUp { floor : Int }
    | IndividualSelect Int Item
    | RangeSelect Int Item
    | RemoveItem Item
    | RemoveSelectedItems
    | RenameItem Item
    | ReplaceAddOrCreateKind Item.Kind
    | ResolveSymlink { follow : Bool } Int Item
    | Select Int Item
    | ShowRenameItemModal Item
    | SidebarMsg Drive.Sidebar.Msg
    | ToggleExpandedSidebar
    | ToggleSidebarAddOrCreate
      -----------------------------------------
      -- File System
      -----------------------------------------
    | GotFsDirectoryList Json.Value
    | GotFsError String
      -----------------------------------------
      -- Sharing
      -----------------------------------------
    | CheckUsernameExistanceForSharingWhenSettled String
    | CheckUsernameExistanceForSharing String
    | GotFsShareError String
    | GotFsShareLink String
    | ShareItem Item
    | ShowShareItemModal Item
      -----------------------------------------
      -- 🌏 Common
      -----------------------------------------
    | GoToRoute Route
    | HideHelpfulNote
    | HideModal
    | ReloadApplication
    | RemoveContextMenu
    | RemoveHelpfulNote
    | Reset Route
    | SetModalState String String
    | ShowContextMenu (ContextMenu Msg) Mouse.Event
    | ShowContextMenuWithCoordinates Coordinates (ContextMenu Msg)
    | ShowHelpfulNote String
      -----------------------------------------
      -- 🐚 Other
      -----------------------------------------
    | AppUpdateAvailable
    | AppUpdateFinished
    | Blurred Html.ElementIdentifiers
    | Focused Html.ElementIdentifiers
    | GotInitialisationError String
    | HandleWebnativeError Webnative.Error
    | HideWelcomeMessage
    | Initialise (Maybe Authentication.Essentials)
    | KeyboardInteraction Keyboard.Msg
    | LinkClicked Browser.UrlRequest
    | LostWindowFocus
    | Ready { fileSystem : Maybe Json.Value, program : Json.Value }
    | RedirectToLobby
    | ScreenSizeChanged Int Int
    | SetCurrentTime Time.Posix
    | ToastyMsg (Toasty.Msg (Notification Msg) Model)
    | ToggleLoadingOverlay { on : Bool }
    | UrlChanged Url


{-| State management.
-}
type alias Organizer model =
    Management.Manager Msg model


type alias Manager =
    Organizer Model
