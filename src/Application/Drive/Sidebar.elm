module Drive.Sidebar exposing (..)

-- 🧩


type Msg
    = PlaintextEditorInput String
    | PlaintextEditorSave
    | DetailsShowPreviewOverlay


type Model
    = Details
        { paths : List String
        , showPreviewOverlay : Bool
        }
    | EditPlaintext
        { path : String

        -- Nothing means Loading
        , editor : Maybe EditorModel
        }
    | AddOrCreate AddOrCreateModel


type alias EditorModel =
    { text : String
    , originalText : String
    , isSaving : Bool
    }


type alias AddOrCreateModel =
    { input : String
    }



-- 🌱


details : List String -> Model
details paths =
    Details { paths = paths, showPreviewOverlay = False }


addOrCreate : AddOrCreateModel
addOrCreate =
    { input = "" }
