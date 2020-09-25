module FileSystem exposing (..)

import Json.Decode as Json
import Time



-- 🧩


type alias Item =
    { cid : String
    , name : String
    , path : String
    , posixTime : Maybe Time.Posix
    , size : Int
    , typ : String
    }


type Status
    = NotNeeded
    | Loading
    | Error String
      --
    | InitialListing
    | AdditionalListing
    | Operation Operation
      --
    | Ready


type Operation
    = AddingFiles
    | CreatingDirectory
    | Deleting



-- DECODING


itemDecoder : Json.Decoder Item
itemDecoder =
    Json.map6
        Item
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
