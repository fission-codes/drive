module Drive.Sidebar exposing (..)

import Drive.Item exposing (Kind(..))
import Webnative.Path exposing (Encapsulated, File, Path)



-- 🧩


type Msg
    = DetailsShowPreviewOverlay
    | PlaintextEditorInput String
    | PlaintextEditorSave


type Tag
    = SavedFile { path : Path File }
    | LoadedFile { path : Path File }


type Model
    = AddOrCreate AddOrCreateModel
    | Details
        { paths : List (Path Encapsulated)
        , showPreviewOverlay : Bool
        }
    | EditPlaintext
        { path : Path File

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


details : List (Path Encapsulated) -> Model
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
