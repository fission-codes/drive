module Authentication.State exposing (..)

import Authentication.Types exposing (SignUpContext)
import FFS.State as FFS
import Ipfs
import Ports
import Return exposing (return)
import Routing exposing (Route(..))
import Types exposing (Manager)



-- 📣


adjustSignUpContext : (SignUpContext -> String -> SignUpContext) -> String -> Manager
adjustSignUpContext modifier input model =
    case model.route of
        CreateAccount context ->
            Return.singleton { model | route = CreateAccount (modifier context input) }

        _ ->
            Return.singleton model


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
