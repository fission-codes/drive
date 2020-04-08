module Authentication.State exposing (..)

import Authentication.Types exposing (SignUpContext)
import Debouncing
import FFS.State as FFS
import Ipfs
import Ports
import Return exposing (return)
import Return.Extra as Return
import Routing exposing (Route(..))
import Types exposing (Manager, Msg(..))



-- 📣


checkIfUsernameIsAvailable : String -> Manager
checkIfUsernameIsAvailable username =
    Return.communicate (Ports.checkIfUsernameIsAvailable username)


gotSignUpEmailInput : String -> Manager
gotSignUpEmailInput input =
    adjustSignUpContext_ (\c -> { c | email = input })


gotSignUpUsernameInput : String -> Manager
gotSignUpUsernameInput input model =
    model
        |> adjustSignUpContext_ (\c -> { c | username = input, usernameIsAvailable = Nothing })
        |> Return.command
            (input
                |> CheckIfUsernameIsAvailable
                |> Debouncing.usernameAvailability.provideInput
                |> Return.task
            )


reportUsernameAvailability : Bool -> Manager
reportUsernameAvailability isAvailable =
    adjustSignUpContext_ (\c -> { c | usernameIsAvailable = Just isAvailable })


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



-- ⚗️


adjustSignUpContext_ : (SignUpContext -> SignUpContext) -> Manager
adjustSignUpContext_ modifier model =
    case model.route of
        CreateAccount context ->
            Return.singleton { model | route = CreateAccount (modifier context) }

        _ ->
            Return.singleton model
