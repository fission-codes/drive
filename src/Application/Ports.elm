port module Ports exposing (..)

import Json.Decode as Json



-- 📣


port ipfsListDirectory : String -> Cmd msg


port ipfsSetup : () -> Cmd msg


port removeStoredRootCid : () -> Cmd msg


port storeRootCid : String -> Cmd msg



-- 📰


port ipfsCompletedSetup : (() -> msg) -> Sub msg


port ipfsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port ipfsGotError : (String -> msg) -> Sub msg
