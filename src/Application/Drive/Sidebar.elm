module Drive.Sidebar exposing (..)

-- 🧩


type Msg
    = DetailsShowPreviewOverlay
    | PlaintextEditorInput String
    | PlaintextEditorSave


type Tag
    = SavedFile { path : String }
    | LoadedFile { path : String }


type Model
    = AddOrCreate AddOrCreateModel
    | Details
        { paths : List String
        , showPreviewOverlay : Bool
        }
    | EditPlaintext
        { path : String

        -- Nothing means Loading
        , editor : Maybe EditorModel
        }


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
