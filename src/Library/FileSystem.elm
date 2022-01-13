module FileSystem exposing (..)

import Json.Decode as Json
import Time



-- 🧩


type alias HardLinkAlias =
    { cid : String
    , name : String
    , path : String
    , posixTime : Maybe Time.Posix
    , readOnly : Bool
    , size : Int
    , typ : String
    }


type alias SoftLinkAlias =
    { ipns : String
    , name : String
    , path : String
    , readOnly : Bool
    }


type Item
    = HardLink HardLinkAlias
    | SoftLink SoftLinkAlias


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
    Json.oneOf
        [ Json.map HardLink hardLinkDecoder
        , Json.map SoftLink softLinkDecoder
        ]


softLinkDecoder : Json.Decoder SoftLinkAlias
softLinkDecoder =
    Json.map4
        SoftLinkAlias
        (Json.field "ipns" Json.string)
        (Json.field "name" Json.string)
        (Json.field "path" Json.string)
        readOnlyDecoder


hardLinkDecoder : Json.Decoder HardLinkAlias
hardLinkDecoder =
    Json.map7
        HardLinkAlias
        (Json.field "cid" Json.string)
        (Json.field "name" Json.string)
        (Json.field "path" Json.string)
        (Json.int
            |> Json.at [ "mtime", "secs" ]
            |> Json.maybe
            |> Json.map (Maybe.map convertTime)
        )
        readOnlyDecoder
        (Json.field "size" Json.int)
        (Json.field "type" Json.string)


convertTime : Int -> Time.Posix
convertTime int =
    Time.millisToPosix (int // 1000)


readOnlyDecoder : Json.Decoder Bool
readOnlyDecoder =
    Json.bool
        |> Json.field "readOnly"
        |> Json.maybe
        |> Json.map (Maybe.withDefault False)



-- 🛠


name : Item -> String
name item =
    case item of
        HardLink h ->
            h.name

        SoftLink s ->
            s.name
