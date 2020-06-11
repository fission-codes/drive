module FS.State exposing (..)

import Common
import Ipfs
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (..)



-- 🚀
--
-- SETUP


boot : Manager
boot model =
    case ( Common.isAuthenticatedAndNotExploring model, model.foundation ) of
        ( True, Just { resolved } ) ->
            { cid = resolved
            , pathSegments = Routing.treePathSegments model.route
            }
                |> Ports.fsLoad
                |> return model

        _ ->
            GetDirectoryList
                |> Return.task
                |> return model



-- 🐚
--
-- LIFE


gotError : String -> Manager
gotError error model =
    -- TODO: Show error notification
    -- This could be something like, "directory already exists".
    Return.singleton { model | ipfs = Ipfs.Ready }


listDirectory : Manager
listDirectory model =
    if Common.isAuthenticatedAndNotExploring model then
        { pathSegments = Routing.treePathSegments model.route }
            |> Ports.fsListDirectory
            |> return model

    else
        GetDirectoryList
            |> Return.task
            |> return model
