port module Ports exposing (..)

import Foundation exposing (Foundation)
import Json.Decode as Json
import Types



-- 📣


port copyToClipboard : String -> Cmd msg


port deauthenticate : () -> Cmd msg


port redirectToLobby : () -> Cmd msg


port renderMedia : { id : String, name : String, path : String, useFS : Bool } -> Cmd msg


port removeStoredFoundation : () -> Cmd msg


port showNotification : String -> Cmd msg


port storeFoundation : Foundation -> Cmd msg



-- 📣  ░░  FILE SYSTEM


port fsAddContent :
    { blobs : List { path : String, url : String }
    , pathSegments : List String
    }
    -> Cmd msg


port fsCreateDirectory : { pathSegments : List String } -> Cmd msg


port fsListDirectory : { pathSegments : List String } -> Cmd msg


port fsLoad : { cid : String, pathSegments : List String } -> Cmd msg


port fsNew : { dnsLink : String } -> Cmd msg


port fsRemoveItem : { pathSegments : List String } -> Cmd msg



-- 📣  ░░  IPFS


port ipfsListDirectory : { address : String, pathSegments : List String } -> Cmd msg


port ipfsResolveAddress : String -> Cmd msg


port ipfsSetup : () -> Cmd msg



-- 📣  ░░  USER


port annihilateKeys : () -> Cmd msg



-- 📰  ░░  FILE SYSTEM


port fsGotError : (String -> msg) -> Sub msg



-- 📰  ░░  IPFS


port ipfsCompletedSetup : (() -> msg) -> Sub msg


port ipfsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port ipfsGotError : (String -> msg) -> Sub msg


port ipfsGotResolvedAddress : (Foundation -> msg) -> Sub msg


port ipfsReplaceResolvedAddress : ({ cid : String } -> msg) -> Sub msg
