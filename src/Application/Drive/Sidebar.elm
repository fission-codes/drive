module Drive.Sidebar exposing (..)

-- 🧩


type Msg
    = DetailsShowPreviewOverlay
    | PlaintextEditorInput String
    | PlaintextEditorSave


type Tag
    = SavedFile { path : List String }
    | LoadedFile { path : List String }


type Model
    = AddOrCreate AddOrCreateModel
    | Details
        { paths : List (List String)
        , showPreviewOverlay : Bool
        }
    | EditPlaintext
        { path : List String

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


details : List (List String) -> Model
details paths =
    Details { paths = paths, showPreviewOverlay = False }


addOrCreate : AddOrCreateModel
addOrCreate =
    { input = "" }
