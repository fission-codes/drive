module Drive.Types exposing (..)

import Item exposing (Item)



-- 📣


type Msg
    = CopyLink Item
    | DigDeeper { directoryName : String }
    | GoUp { floor : Int }
    | RemoveSelection
    | Select Item
    | ShowPreviewOverlay
    | ToggleLargePreview
