module Drive.Sidebar exposing (..)

-- 🧩


type Msg
    = PlaintextEditorInput String
    | PlaintextEditorSave
    | DetailsShowPreviewOverlay


type alias Model =
    { path : String
    , mode : Mode
    }


type Mode
    = Details { showPreviewOverlay : Bool }
      -- Nothing means Loading
    | EditPlaintext (Maybe EditorModel)


type alias EditorModel =
    { text : String
    , originalText : String
    }


type alias AddOrCreateModel =
    { input : String
    }



-- 🌱


details : Mode
details =
    Details { showPreviewOverlay = False }


addOrCreate : AddOrCreateModel
addOrCreate =
    { input = "" }
