module Ipfs exposing (..)

import Json.Decode



-- 🧩


type alias ListItem =
    { name : String
    , path : String
    , size : Int
    , typ : String
    }


type State
    = Connecting
    | Ready



-- DECODING


listItemDecoder : Json.Decode.Decoder ListItem
listItemDecoder =
    Json.Decode.map4
        ListItem
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "path" Json.Decode.string)
        (Json.Decode.field "size" Json.Decode.int)
        (Json.Decode.field "type" Json.Decode.string)
