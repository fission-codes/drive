module Drive.Sidebar exposing (..)

-- 🧩


type Mode
    = AddOrCreate
    | DetailsForSelection
    | EditPlaintext



-- 🏔


defaultMode : Mode
defaultMode =
    DetailsForSelection
