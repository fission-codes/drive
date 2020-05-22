module Authentication.State exposing (..)

import FS.State as FS
import Ipfs
import Ports
import Return
import Types exposing (Manager, Msg(..))



-- 📣


signIn : Manager
signIn model =
    case model.foundation of
        Just { unresolved } ->
            { model
                | ipfs = Ipfs.InitialListing
            }
                |> FS.boot
                |> Return.command
                    (Ports.storeAuthEssentials
                        { dnsLink = unresolved
                        , ucan = "TODO"
                        }
                    )

        Nothing ->
            Return.singleton model
