port module Ports exposing (listDirectory)

import Json.Decode as Json



-- 📣


port listDirectory : String -> Cmd msg



-- 📰


port gotDirectoryList : (Json.Value -> msg) -> Sub msg
