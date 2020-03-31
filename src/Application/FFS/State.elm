module FFS.State exposing (..)

import Maybe.Extra as Maybe
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (..)



-- 🚀


boot : Manager
boot model =
    -- TODO? Ports.ipfsPrefetchTree
    case ( model.authenticated, model.foundation ) of
        ( Just { dnslink }, Just { unresolved, resolved } ) ->
            if dnslink == unresolved then
                { cid = resolved
                , pathSegments = Routing.treePathSegments model.route
                }
                    |> Ports.ffsLoad
                    |> return model

            else
                -- TODO
                Return.singleton model

        _ ->
            GetDirectoryList
                |> Return.task
                |> return model


listDirectory : Manager
listDirectory model =
    if Maybe.isJust model.authenticated then
        { pathSegments = Routing.treePathSegments model.route }
            |> Ports.ffsListDirectory
            |> return model

    else
        GetDirectoryList
            |> Return.task
            |> return model
