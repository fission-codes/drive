module Coordinates exposing (Coordinates, Viewport, fromTuple)

-- 🧩


type alias Coordinates =
    { x : Float, y : Float }


type alias Viewport =
    { height : Float
    , width : Float
    }



-- 🛠


fromTuple : ( Float, Float ) -> Coordinates
fromTuple ( x, y ) =
    { x = x
    , y = y
    }
