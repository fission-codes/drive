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
                | authenticated = Just { dnsLink = unresolved }
                , ipfs = Ipfs.InitialListing
            }
                |> FS.boot
                |> Return.command (Ports.storeAuthDnsLink unresolved)

        Nothing ->
            Return.singleton model
