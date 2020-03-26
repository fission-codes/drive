module Types exposing (..)

{-| Root-level types.
-}

import Browser
import Browser.Navigation as Navigation
import ContextMenu exposing (ContextMenu)
import Debouncer.Messages as Debouncer exposing (Debouncer)
import Drive.Item exposing (Item)
import Drive.Sidebar
import File exposing (File)
import Html.Events.Extra.Drag as Drag
import Html.Events.Extra.Mouse as Mouse
import Ipfs
import Json.Decode as Json
import Keyboard
import Management
import Routing exposing (Route)
import Time
import Url exposing (Url)



-- ⛩


{-| Flags passed initializing the application.
-}
type alias Flags =
    { foundation : Maybe Foundation
    }



-- 🌱


{-| Model of our UI state.
-}
type alias Model =
    { currentTime : Time.Posix
    , directoryList : Result String (List Item)
    , contextMenu : Maybe (ContextMenu Msg)
    , dragndropMode : Bool
    , exploreInput : Maybe String
    , foundation : Maybe Foundation
    , helpfulNote : Maybe { faded : Bool, note : String }
    , ipfs : Ipfs.Status
    , isFocused : Bool
    , navKey : Navigation.Key
    , pressedKeys : List Keyboard.Key
    , route : Route
    , selectedPath : Maybe String
    , showLoadingOverlay : Bool
    , url : Url

    -----------------------------------------
    -- Debouncers
    -----------------------------------------
    , loadingDebouncer : Debouncer Msg
    , notificationsDebouncer : Debouncer Msg

    -----------------------------------------
    -- Sidebar
    -----------------------------------------
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
      -----------------------------------------
      -- Drive
      -----------------------------------------
    | ActivateSidebarMode Drive.Sidebar.Mode
    | AddFiles File (List File)
    | AskUserForFilesToAdd
    | CloseSidebar
    | CopyPublicUrl { item : Item, presentable : Bool }
    | CopyToClipboard { clip : String, notification : String }
    | DigDeeper { directoryName : String }
    | DownloadItem Item
    | DroppedSomeFiles Drag.Event
    | GoUp { floor : Int }
    | Select Item
    | ShowPreviewOverlay
    | ToggleExpandedSidebar
    | ToggleSidebarMode Drive.Sidebar.Mode
      -----------------------------------------
      -- Explore
      -----------------------------------------
    | Explore
    | GotInput String
    | Reset
      -----------------------------------------
      -- Ipfs
      -----------------------------------------
    | GotDirectoryList Json.Value
    | GotError String
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
    | ShowHelpfulNote String
      -----------------------------------------
      -- 🐚 Other
      -----------------------------------------
    | Blurred
    | Focused
    | KeyboardInteraction Keyboard.Msg
    | LinkClicked Browser.UrlRequest
    | ScreenSizeChanged Int Int
    | SetCurrentTime Time.Posix
    | ToggleLoadingOverlay { on : Bool }
    | UrlChanged Url


{-| State management.
-}
type alias Organizer model =
    Management.Manager Msg model


type alias Manager =
    Organizer Model



-- 🧩


type alias Foundation =
    { isDnsLink : Bool
    , resolved : String
    , unresolved : String
    }
