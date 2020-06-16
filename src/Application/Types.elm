module Types exposing (..)

{-| Root-level types.
-}

import Authentication.Essentials as Authentication
import Browser
import Browser.Navigation as Navigation
import ContextMenu exposing (ContextMenu)
import Coordinates exposing (Coordinates)
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Drive.Item exposing (Item)
import Drive.Sidebar
import Foundation exposing (Foundation)
import Html.Events.Extra.Mouse as Mouse
import Ipfs
import Json.Decode as Json
import Keyboard
import Management
import Mode exposing (Mode)
import Notifications exposing (Notification)
import Routing exposing (Route)
import Time
import Toasty
import Url exposing (Url)



-- ⛩


{-| Flags passed initializing the application.
-}
type alias Flags =
    { authenticated : Maybe Authentication.Essentials
    , currentTime : Int
    , foundation : Maybe Foundation
    , lastFsOperation : Int
    , usersDomain : String
    , viewportSize : { height : Int, width : Int }
    }



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { authenticated : Maybe Authentication.Essentials
    , currentTime : Time.Posix
    , directoryList : Result String { floor : Int, items : List Item }
    , contextMenu : Maybe (ContextMenu Msg)
    , dragndropMode : Bool
    , exploreInput : Maybe String
    , foundation : Maybe Foundation
    , helpfulNote : Maybe { faded : Bool, note : String }
    , ipfs : Ipfs.Status
    , isFocused : Bool
    , mode : Mode
    , navKey : Navigation.Key
    , pressedKeys : List Keyboard.Key
    , route : Route
    , viewportSize : { height : Int, width : Int }
    , selectedPath : Maybe String
    , showLoadingOverlay : Bool
    , toasties : Toasty.Stack (Notification Msg)
    , url : Url
    , usersDomain : String

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , loadingDebouncer : Debouncer Msg
    , notificationsDebouncer : Debouncer Msg
    , usernameAvailabilityDebouncer : Debouncer Msg

    -----------------------------------------
    -- Sidebar
    -----------------------------------------
    , createDirectoryInput : String
    , expandSidebar : Bool
    , showPreviewOverlay : Bool
    , sidebarMode : Drive.Sidebar.Mode
    }



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
    | UsernameAvailabilityDebouncerMsg (Debouncer.Msg Msg)
      -----------------------------------------
      -- Drive
      -----------------------------------------
    | ActivateSidebarMode Drive.Sidebar.Mode
    | AddFiles { blobs : List { path : String, url : String } }
    | CloseSidebar
    | CopyPublicUrl { item : Item, presentable : Bool }
    | CopyToClipboard { clip : String, notification : String }
    | CreateDirectory
    | DigDeeper { directoryName : String }
    | DownloadItem Item
    | GotCreateDirectoryInput String
    | GoUp { floor : Int }
    | RemoveItem Item
    | Select Item
    | ShowPreviewOverlay
    | ToggleExpandedSidebar
    | ToggleSidebarMode Drive.Sidebar.Mode
      -----------------------------------------
      -- Explore
      -----------------------------------------
    | ChangeCid
    | GotInput String
    | Reset Route
      -----------------------------------------
      -- File System
      -----------------------------------------
    | GotFsError String
      -----------------------------------------
      -- Ipfs
      -----------------------------------------
    | GetDirectoryList
    | GotDirectoryList Json.Value
    | GotIpfsError String
    | GotResolvedAddress Foundation
    | ReplaceResolvedAddress { cid : String }
    | SetupCompleted
      -----------------------------------------
      -- 🌏 Common
      -----------------------------------------
    | HideHelpfulNote
    | RemoveContextMenu
    | RemoveHelpfulNote
    | ShowContextMenu (ContextMenu Msg) Mouse.Event
    | ShowContextMenuWithCoordinates Coordinates (ContextMenu Msg)
    | ShowHelpfulNote String
      -----------------------------------------
      -- 🐚 Other
      -----------------------------------------
    | Blurred
    | Focused
    | GoToRoute Route
    | KeyboardInteraction Keyboard.Msg
    | LinkClicked Browser.UrlRequest
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
