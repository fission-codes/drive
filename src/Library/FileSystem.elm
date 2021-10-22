module FileSystem exposing (..)

import Json.Decode as Json
import Time



-- 🧩


type alias HardLinkAlias =
    { cid : String
    , name : String
    , path : String
    , posixTime : Maybe Time.Posix
    , size : Int
    , typ : String
    }


type alias SoftLinkAlias =
    { ipns : String
    , name : String
    , path : String
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
    Json.map3
        SoftLinkAlias
        (Json.field "ipns" Json.string)
        (Json.field "name" Json.string)
        (Json.field "path" Json.string)


hardLinkDecoder : Json.Decoder HardLinkAlias
hardLinkDecoder =
    Json.map6
        HardLinkAlias
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



-- 🛠


name : Item -> String
name item =
    case item of
        HardLink h ->
            h.name

        SoftLink s ->
            s.name
