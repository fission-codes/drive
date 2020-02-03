module Ipfs.Types exposing (..)

import Json.Decode as Json



-- 📣


type Msg
    = GotDirectoryList Json.Value
    | GotError String
    | SetupCompleted
