module Authentication.External exposing (authenticationUrl, essentialsFromUrl, host)

{-| Regarding `auth.fission.codes`
-}

import Authentication.External.Essentials exposing (Essentials)
import Maybe.Extra as Maybe
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser
import Url.Parser.Query as Query



-- 🏔


host =
    -- "https://auth.fission.codes"
    "http://localhost:8001"



-- 🛠


authenticationUrl : String -> Url -> String
authenticationUrl did url =
    [ Builder.string "did" did
    , Builder.string "redirectTo" (Url.toString url)
    ]
        |> Builder.absolute []
        |> String.append host


essentialsFromUrl : Url -> Maybe Essentials
essentialsFromUrl url =
    { url | path = "" }
        |> Parser.parse (Parser.query essentialQueryParser)
        |> Maybe.join



-- ㊙️


essentialQueryParser =
    Query.map2
        (Maybe.map2
            (\a b ->
                { dnsLink = b ++ ".fission.name"
                , ucan = a
                }
            )
        )
        (Query.string "ucan")
        (Query.string "username")
