module Drive.Sidebar exposing (..)

-- 🧩


type Mode
    = AddOrCreate
    | DetailsForSelection



-- 🏔


defaultMode : Mode
defaultMode =
    DetailsForSelection
