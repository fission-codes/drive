module Drive.Sidebar exposing (..)

-- 🧩


type Mode
    = AddOrCreate
    | DetailsForSelection
    | EditPlaintext EditorModel


type alias EditorModel =
    { text : String
    , hasChanges : Bool
    }



-- 🏔


defaultMode : Mode
defaultMode =
    DetailsForSelection
