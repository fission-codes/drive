module Html.Ext exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Maybe.Extra as Maybe


{-| Information about a HTML element as to identify it.
-}
type alias ElementIdentifiers =
    { tagName : String
    , class : List String
    , id : Maybe String
    }


elementIdentifiersDecoder : Decoder ElementIdentifiers
elementIdentifiersDecoder =
    Decode.map3
        (\t i c ->
            { tagName = t
            , class = c
            , id = i
            }
        )
        (Decode.field "tagName" Decode.string)
        (Decode.maybe <| Decode.field "id" Decode.string)
        (Decode.string
            |> Decode.field "class"
            |> Decode.maybe
            |> Decode.map (Maybe.unwrap [] <| String.split " ")
        )


isInputElement : ElementIdentifiers -> Bool
isInputElement e =
    String.toUpper e.tagName == "INPUT" || String.toUpper e.tagName == "TEXTAREA"
