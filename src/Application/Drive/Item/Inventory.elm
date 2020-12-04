module Drive.Item.Inventory exposing (..)

import Drive.Item exposing (Item)
import List.Extra as List



-- 🧩


type alias Inventory =
    { floor : Int
    , items : List Item
    , selection : Selection
    }


type alias Selection =
    List { index : Int, isFirst : Bool }



-- 🛠


clearSelection : Inventory -> Inventory
clearSelection inventory =
    { inventory | selection = [] }


default : Inventory
default =
    { floor = 1, items = [], selection = [] }


autoSelectOnSingleFileView : List String -> Inventory -> Inventory
autoSelectOnSingleFileView pathSegments ({ items } as inventory) =
    { inventory
        | selection =
            case items of
                [ item ] ->
                    if Just item.name == List.last pathSegments then
                        [ { index = 0, isFirst = True } ]

                    else
                        []

                _ ->
                    []
    }


selectionItems : Inventory -> List Item
selectionItems { floor, items, selection } =
    List.foldr
        (\{ index } acc ->
            case List.getAt index items of
                Just item ->
                    if floor == 1 && item.name == "public" then
                        acc

                    else
                        item :: acc

                Nothing ->
                    acc
        )
        []
        selection
