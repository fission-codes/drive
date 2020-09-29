port module Ports exposing (..)

import Json.Decode as Json
import Radix



-- 📣


port copyToClipboard : String -> Cmd msg


port deauthenticate : () -> Cmd msg


port redirectToLobby : () -> Cmd msg


port renderMedia : { id : String, name : String, path : String, useFS : Bool } -> Cmd msg


port showNotification : String -> Cmd msg



-- 📣  ░░  FILE SYSTEM


port fsAddContent :
    { blobs : List { path : String, url : String }
    , pathSegments : List String
    }
    -> Cmd msg


port fsCreateDirectory : { pathSegments : List String } -> Cmd msg


port fsDownloadItem : { pathSegments : List String } -> Cmd msg


port fsListDirectory : { pathSegments : List String } -> Cmd msg


port fsListPublicDirectory : { pathSegments : List String, root : String } -> Cmd msg


port fsRemoveItem : { pathSegments : List String } -> Cmd msg


{-| `pathSegments` refers to the new path.
-}
port fsMoveItem : { currentPathSegments : List String, pathSegments : List String } -> Cmd msg



-- 📰  ░░  FILE SYSTEM


port fsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port fsGotError : (String -> msg) -> Sub msg
