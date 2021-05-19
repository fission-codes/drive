module Drive.Sidebar exposing (..)

import Drive.Item exposing (Kind(..))



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
    { kind : Kind
    , input : String
    , isCreating : Bool
    }



-- 🌱


addOrCreate : AddOrCreateModel
addOrCreate =
    { kind = Directory
    , input = ""
    , isCreating = False
    }


details : List String -> Model
details paths =
    Details
        { paths = paths
        , showPreviewOverlay = False
        }



-- 🛠


mapAddOrCreate : (AddOrCreateModel -> AddOrCreateModel) -> Model -> Model
mapAddOrCreate fn model =
    case model of
        AddOrCreate m ->
            AddOrCreate (fn m)

        m ->
            m
