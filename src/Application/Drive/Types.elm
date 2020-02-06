module Drive.Types exposing (..)

import Item exposing (Item)



-- 📣


type Msg
    = DigDeeper { directoryName : String }
    | GoUp { floor : Int }
    | RemoveSelection
    | Select Item
    | ToggleLargePreview
