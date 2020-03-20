module ContextMenu exposing (ContextMenu, Hook(..), Item(..), ItemProperties, build, position, properties)

import Coordinates exposing (Coordinates)
import FeatherIcons
import Html exposing (Html)



-- 🧩


type ContextMenu msg
    = ContextMenu Hook (List (Item msg)) Coordinates


type Item msg
    = Item (ItemProperties msg)
    | Divider


type alias ItemProperties msg =
    { icon : FeatherIcons.Icon
    , label : String
    , active : Bool

    --
    , href : Maybe String
    , msg : Maybe msg
    }


type Hook
    = TopRight



-- 🛠


build : Hook -> List (Item msg) -> ContextMenu msg
build hook items =
    ContextMenu hook items { x = 0, y = 0 }


position : ContextMenu msg -> Coordinates -> ContextMenu msg
position (ContextMenu hook items _) coordinates =
    ContextMenu hook items coordinates


properties : ContextMenu msg -> { items : List (Item msg), coordinates : Coordinates }
properties (ContextMenu _ items coordinates) =
    { items = items
    , coordinates = coordinates
    }
