module Drive.Item.Inventory exposing (..)

import Drive.Item exposing (Item)
import List.Extra as List
import Webnative.Path as Path exposing (Encapsulated, Path)



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


autoSelectOnSingleFileView : Path Encapsulated -> Inventory -> Inventory
autoSelectOnSingleFileView path ({ items } as inventory) =
    { inventory
        | selection =
            case items of
                [ item ] ->
                    if Just item.name == List.last (Path.unwrap path) then
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
