port module Ports exposing (..)

import Json.Decode as Json
import Types exposing (Foundation)



-- 📣


port copyToClipboard : String -> Cmd msg


port ipfsListDirectory : { cid : String, pathSegments : List String } -> Cmd msg


port ipfsPrefetchTree : String -> Cmd msg


port ipfsResolveAddress : String -> Cmd msg


port ipfsSetup : () -> Cmd msg


port renderMedia : { id : String, name : String, path : String } -> Cmd msg


port removeStoredFoundation : () -> Cmd msg


port showNotification : String -> Cmd msg


port storeFoundation : Foundation -> Cmd msg



-- 📰


port ipfsCompletedSetup : (() -> msg) -> Sub msg


port ipfsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port ipfsGotError : (String -> msg) -> Sub msg


port ipfsGotResolvedAddress : (Foundation -> msg) -> Sub msg
