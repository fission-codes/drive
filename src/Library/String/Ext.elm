module String.Ext exposing (..)

{-| More functions for working with Strings.
-}

-- 🛠


{-| Flipped version of `append`.
-}
addSuffix : String -> String -> String
addSuffix a b =
    String.append b a


{-| Chop something from the end of a string until it's not there anymore.
-}
chopEnd : String -> String -> String
chopEnd needle str =
    if String.endsWith needle str then
        str
            |> String.dropRight (String.length needle)
            |> chopEnd needle

    else
        str


{-| Chop something from the beginning of a string until it's not there anymore.
-}
chopStart : String -> String -> String
chopStart needle str =
    if String.startsWith needle str then
        str
            |> String.dropLeft (String.length needle)
            |> chopStart needle

    else
        str


{-| Chop something from the beginning and end until it's not there anymore.
-}
chop : String -> String -> String
chop needle =
    chopStart needle >> chopEnd needle
