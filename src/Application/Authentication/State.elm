module Authentication.State exposing (..)

import FFS.State as FFS
import Ipfs
import Ports
import Return exposing (return)
import Types exposing (Manager)



-- 📣


signIn : Manager
signIn model =
    case model.foundation of
        Just { unresolved } ->
            { model
                | authenticated = Just { dnslink = unresolved }
                , ipfs = Ipfs.InitialListing
            }
                |> FFS.boot
                |> Return.command (Ports.storeAuthDnsLink unresolved)

        Nothing ->
            Return.singleton model
