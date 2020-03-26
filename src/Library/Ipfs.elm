module Ipfs exposing (..)

import Json.Decode
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
    | Ready



-- DECODING


listItemDecoder : Json.Decode.Decoder ListItem
listItemDecoder =
    Json.Decode.map6
        ListItem
        (Json.Decode.field "cid" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "path" Json.Decode.string)
        (Json.Decode.int
            |> Json.Decode.at [ "mtime", "secs" ]
            |> Json.Decode.maybe
            |> Json.Decode.map (Maybe.map convertTime)
        )
        (Json.Decode.field "size" Json.Decode.int)
        (Json.Decode.field "type" Json.Decode.string)


convertTime : Int -> Time.Posix
convertTime int =
    Time.millisToPosix (int // 1000)
