module Authentication.Essentials exposing (..)

-- 🧩


type alias Essentials =
    { newUser : Bool
    , username : String
    }


dnsLink : String -> Essentials -> String
dnsLink usersDomain { username } =
    username ++ "." ++ usersDomain
