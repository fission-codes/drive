port module Ports exposing (..)

import Json.Decode as Json
import Types exposing (Foundation)



-- 📣


port copyToClipboard : String -> Cmd msg


port renderMedia : { id : String, name : String, path : String, useFFS : Bool } -> Cmd msg


port removeStoredAuthDnsLink : () -> Cmd msg


port removeStoredFoundation : () -> Cmd msg


port showNotification : String -> Cmd msg


port storeAuthDnsLink : String -> Cmd msg


port storeFoundation : Foundation -> Cmd msg



-- 📣  ░░  FFS


port ffsAddContent :
    { blobs : List { name : String, url : String }
    , pathSegments : List String
    }
    -> Cmd msg


port ffsCreateDirectory : { pathSegments : List String } -> Cmd msg


port ffsListDirectory : { pathSegments : List String } -> Cmd msg


port ffsLoad : { cid : String, pathSegments : List String } -> Cmd msg



-- 📣  ░░  FISSION


port checkIfUsernameIsAvailable : String -> Cmd msg


port createAccount : () -> Cmd msg



-- 📣  ░░  IPFS


port ipfsListDirectory : { address : String, pathSegments : List String } -> Cmd msg


port ipfsPrefetchTree : String -> Cmd msg


port ipfsResolveAddress : String -> Cmd msg


port ipfsSetup : () -> Cmd msg



-- 📰


port ipfsCompletedSetup : (() -> msg) -> Sub msg


port ipfsGotDirectoryList : (Json.Value -> msg) -> Sub msg


port ipfsGotError : (String -> msg) -> Sub msg


port ipfsGotResolvedAddress : (Foundation -> msg) -> Sub msg


port ipfsReplaceResolvedAddress : ({ cid : String } -> msg) -> Sub msg


port reportCreateAccountResult : ({ status : Int } -> msg) -> Sub msg


port reportUsernameAvailability : (Bool -> msg) -> Sub msg
