port module Ports exposing (..)

import Authentication.Essentials as Authentication
import Drive.Item exposing (PortablePath)
import Json.Decode as Json



-- 📣


port blurActiveElement : () -> Cmd msg


port copyToClipboard : String -> Cmd msg


port deauthenticate : () -> Cmd msg


port redirectToLobby : () -> Cmd msg


port showNotification : String -> Cmd msg



-- 📣  ░░  FILE SYSTEM


port fsAddContent :
    { blobs : List { path : String, url : String }
    , toPath : Json.Value
    }
    -> Cmd msg


port fsDownloadItem : PortablePath -> Cmd msg


port fsListDirectory : PortablePath -> Cmd msg


port fsListPublicDirectory : { path : Json.Value, root : String } -> Cmd msg


port fsRemoveItem : PortablePath -> Cmd msg


port fsResolveItem : { follow : Bool, index : Int, path : Json.Value } -> Cmd msg


port fsMoveItem : { fromPath : Json.Value, toPath : Json.Value } -> Cmd msg


port fsShareItem : { path : Json.Value, shareWith : String } -> Cmd msg



-- 📰


port gotInitialisationError : (String -> msg) -> Sub msg


port initialise : (Maybe Authentication.Essentials -> msg) -> Sub msg


port lostWindowFocus : (() -> msg) -> Sub msg


port ready : ({ fileSystem : Maybe Json.Value, program : Json.Value } -> msg) -> Sub msg


port appUpdateAvailable : (() -> msg) -> Sub msg


port appUpdateFinished : (() -> msg) -> Sub msg



-- 📰  ░░  FILE SYSTEM


port fsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port fsGotError : (String -> msg) -> Sub msg


port fsGotShareError : (String -> msg) -> Sub msg


port fsGotShareLink : (String -> msg) -> Sub msg
