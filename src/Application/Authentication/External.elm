module Authentication.External exposing (..)

{-| Regarding `auth.fission.codes`
-}

import Url exposing (Url)
import Url.Builder as Url



-- 🏔


host =
    -- "https://auth.fission.codes"
    "http://localhost:8001"



-- 🛠


createAccountUrl : String -> Url -> String
createAccountUrl didKey url =
    [ Url.string "didKey" didKey
    , Url.string "redirectTo" (Url.toString url)
    ]
        |> Url.absolute [ "create-account" ]
        |> String.append host
