module Dict.Ext exposing (..)

import Dict exposing (Dict)


fetch : comparable -> v -> Dict comparable v -> v
fetch k fallback dict =
    dict
        |> Dict.get k
        |> Maybe.withDefault fallback
