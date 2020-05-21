module ContextMenu exposing (ContextMenu, Hook(..), Item(..), ItemProperties, build, hook, position, properties)

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
    , href : Maybe { newTab : Bool, url : String }
    , msg : Maybe msg
    }


type Hook
    = BottomCenter
    | TopCenterWithoutOffset
    | TopRight



-- 🛠


build : Hook -> List (Item msg) -> ContextMenu msg
build h i =
    ContextMenu h i { x = 0, y = 0 }


position : ContextMenu msg -> Coordinates -> ContextMenu msg
position (ContextMenu h i _) c =
    ContextMenu h i c



-- PROPERTIES


hook : ContextMenu msg -> Hook
hook (ContextMenu h _ _) =
    h


properties : ContextMenu msg -> { hook : Hook, items : List (Item msg), coordinates : Coordinates }
properties (ContextMenu h i c) =
    { hook = h
    , items = i
    , coordinates = c
    }
