port module Ports exposing (..)

import Authentication.Essentials as Authentication
import Json.Decode as Json
import Webnative



-- 📣


port copyToClipboard : String -> Cmd msg


port deauthenticate : () -> Cmd msg


port redirectToLobby : () -> Cmd msg


port showNotification : String -> Cmd msg



-- 📣  ░░  FILE SYSTEM


port fsAddContent :
    { blobs : List { path : String, url : String }
    , pathSegments : List String
    }
    -> Cmd msg


port fsDownloadItem : { pathSegments : List String } -> Cmd msg


port fsListDirectory : { pathSegments : List String } -> Cmd msg


port fsListPublicDirectory : { pathSegments : List String, root : String } -> Cmd msg


port fsRemoveItem : { pathSegments : List String } -> Cmd msg


{-| `pathSegments` refers to the new path.
-}
port fsMoveItem : { currentPathSegments : List String, pathSegments : List String } -> Cmd msg



-- 📰


port gotInitialisationError : (String -> msg) -> Sub msg


port initialise : (Maybe Authentication.Essentials -> msg) -> Sub msg


port lostWindowFocus : (() -> msg) -> Sub msg


port ready : (() -> msg) -> Sub msg


port appUpdateAvailable : (() -> msg) -> Sub msg


port appUpdateFinished : (() -> msg) -> Sub msg



-- 📰  ░░  FILE SYSTEM


port fsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port fsGotError : (String -> msg) -> Sub msg



-- WEBNATIVE ELM


port webnativeRequest : Webnative.Request -> Cmd msg


port webnativeResponse : (Webnative.Response -> msg) -> Sub msg
