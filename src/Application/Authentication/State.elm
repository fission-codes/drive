module Authentication.State exposing (..)

import Authentication.Types exposing (SignUpContext)
import Debouncing
import FFS.State as FFS
import Ipfs
import Json.Decode as Json
import Ports
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (Manager, Msg(..))



-- 📣


checkIfUsernameIsAvailable : String -> Manager
checkIfUsernameIsAvailable username =
    case String.trim username of
        "" ->
            Return.singleton

        u ->
            Return.communicate (Ports.checkIfUsernameIsAvailable u)


createAccount : SignUpContext -> Manager
createAccount context model =
    case context.usernameIsAvailable of
        Just True ->
            { email = context.email
            , username = context.username
            }
                |> Ports.createAccount
                |> return { model | reCreateAccount = Loading }

        _ ->
            Return.singleton model


gotCreateAccountFailure : String -> Manager
gotCreateAccountFailure err model =
    Return.singleton { model | reCreateAccount = Failure err }


gotCreateAccountSuccess : { dnsLink : String } -> Manager
gotCreateAccountSuccess a model =
    Return.singleton { model | authenticated = Just a, reCreateAccount = Success () }


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


gotUsernameAvailability : Bool -> Manager
gotUsernameAvailability isAvailable =
    adjustSignUpContext_ (\c -> { c | usernameIsAvailable = Just isAvailable })


signIn : Manager
signIn model =
    case model.foundation of
        Just { unresolved } ->
            { model
                | authenticated = Just { dnsLink = unresolved }
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
        Routing.CreateAccount context ->
            Return.singleton { model | route = Routing.CreateAccount (modifier context) }

        _ ->
            Return.singleton model
