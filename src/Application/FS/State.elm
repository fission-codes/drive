module Fs.State exposing (..)

import Common
import Foundation exposing (Foundation)
import Ipfs
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (..)



-- 🚀
--
-- SETUP


load : Foundation -> Manager
load { resolved } model =
    { cid = resolved
    , pathSegments = Routing.treePathSegments model.route
    }
        |> Ports.fsLoad
        |> return model


{-| Only load a file system if necessary,
otherwise do a regular IPFS directory list.
-}
loadOrList : Manager
loadOrList model =
    if Common.isAuthenticatedAndNotExploring model then
        case model.foundation of
            Just f ->
                load f model

            Nothing ->
                Return.singleton model

    else
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
