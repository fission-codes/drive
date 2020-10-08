module Drive.Sidebar exposing (..)

-- 🧩


type Mode
    = AddOrCreate
    | DetailsForSelection
    | EditPlaintext EditorModel


type alias EditorModel =
    { text : String
    , originalText : String
    , path : { pathSegments : List String }
    }



-- 🏔


defaultMode : Mode
defaultMode =
    DetailsForSelection
