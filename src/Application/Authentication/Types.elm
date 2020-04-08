module Authentication.Types exposing (..)

-- 🧩


type alias SignUpContext =
    { email : String
    , username : String
    , usernameIsAvailable : Maybe Bool
    }
