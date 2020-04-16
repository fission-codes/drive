module Authentication.Types exposing (..)

import RemoteData exposing (RemoteData)



-- 🧩


type alias SignUpContext =
    { email : String
    , username : String
    , usernameIsAvailable : RemoteData () Bool
    , usernameIsValid : Bool
    }
