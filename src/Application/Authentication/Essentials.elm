module Authentication.Essentials exposing (..)

-- 🧩


type alias Essentials =
    { newUser : Bool
    , username : String
    }


dnsLink : Essentials -> String
dnsLink { username } =
    username ++ ".fission.name"
