module Drive.Sidebar exposing (..)

-- 🧩


type alias Model =
    { expanded : Bool
    , path : String
    , mode : Mode
    }


type Mode
    = Details { showPreviewOverlay : Bool }
    | EditPlaintext EditorModel


type alias EditorModel =
    { text : String
    , originalText : String
    }


type alias AddOrCreateModel =
    { expanded : Bool
    , input : String
    }



-- 🌱


details : Mode
details =
    Details { showPreviewOverlay = False }

addOrCreate : AddOrCreateModel
addOrCreate = { expanded = False, input = ""}