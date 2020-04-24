module Foundation exposing (..)

-- 🧩


type alias Foundation =
    { isDnsLink : Bool
    , resolved : String
    , unresolved : String
    }



-- 🛠


isFission : Foundation -> Bool
isFission { isDnsLink, unresolved } =
    isDnsLink && String.endsWith ".fission.name" unresolved
