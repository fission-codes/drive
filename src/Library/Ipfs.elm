module Ipfs exposing (..)

import Json.Decode as Json
import Time



-- 🧩


type alias ListItem =
    { cid : String
    , name : String
    , path : String
    , posixTime : Maybe Time.Posix
    , size : Int
    , typ : String
    }


type Status
    = Connecting
    | Error String
    | InitialListing
    | AdditionalListing
    | FileSystemOperation
    | Ready



-- DECODING


listItemDecoder : Json.Decoder ListItem
listItemDecoder =
    Json.map6
        ListItem
        (Json.field "cid" Json.string)
        (Json.field "name" Json.string)
        (Json.field "path" Json.string)
        (Json.int
            |> Json.at [ "mtime", "secs" ]
            |> Json.maybe
            |> Json.map (Maybe.map convertTime)
        )
        (Json.field "size" Json.int)
        (Json.field "type" Json.string)


convertTime : Int -> Time.Posix
convertTime int =
    Time.millisToPosix (int // 1000)
