module FS.State exposing (..)

import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (..)



-- 🚀


boot : Manager
boot model =
    case ( model.authenticated, model.foundation ) of
        ( Just _, Just { unresolved, resolved } ) ->
            { cid = resolved
            , pathSegments = Routing.treePathSegments model.route
            }
                |> Ports.fsLoad
                |> return model

        _ ->
            GetDirectoryList
                |> Return.task
                |> return model


listDirectory : Manager
listDirectory model =
    if Maybe.isJust model.authenticated then
        { pathSegments = Routing.treePathSegments model.route }
            |> Ports.fsListDirectory
            |> return model

    else
        GetDirectoryList
            |> Return.task
            |> return model