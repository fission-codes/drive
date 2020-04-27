module Authentication.State exposing (..)

import Authentication.Types exposing (SignUpContext)
import Debouncing
import FS.State as FS
import Ipfs
import Json.Decode as Json
import Ports
import RemoteData exposing (RemoteData(..))
import Return exposing (return)
import Return.Extra as Return
import Routing
import Types exposing (Manager, Msg(..))



-- 📣


checkIfUsernameIsAvailable : Manager
checkIfUsernameIsAvailable model =
    case model.route of
        Routing.CreateAccount context ->
            case context.username of
                "" ->
                    Return.singleton model

                u ->
                    model
                        |> adjustSignUpContext_
                            (\c -> { c | usernameIsAvailable = Loading })
                        |> Return.command
                            (Ports.checkIfUsernameIsAvailable u)

        _ ->
            Return.singleton model


createAccount : SignUpContext -> Manager
createAccount context model =
    case ( context.usernameIsValid, context.usernameIsAvailable ) of
        ( _, Success False ) ->
            Return.singleton model

        ( True, _ ) ->
            let
                dnsLink =
                    context.username ++ ".fission.name"
            in
            { email = String.trim context.email
            , username = String.trim context.username
            }
                |> Ports.createAccount
                |> return
                    { model
                        | exploreInput = Just dnsLink
                        , reCreateAccount = Loading
                    }

        _ ->
            Return.singleton model


gotCreateAccountFailure : String -> Manager
gotCreateAccountFailure err model =
    Return.singleton { model | reCreateAccount = Failure err }


gotCreateAccountSuccess : { dnsLink : String } -> Manager
gotCreateAccountSuccess a model =
    Return.singleton { model | authenticated = Just a, reCreateAccount = Success () }


gotSignUpEmailInput : String -> Manager
gotSignUpEmailInput input model =
    adjustSignUpContext_
        (\c -> { c | email = input })
        { model | reCreateAccount = NotAsked }


gotSignUpUsernameInput : String -> Manager
gotSignUpUsernameInput input model =
    { model | reCreateAccount = NotAsked }
        |> adjustSignUpContext_
            (\c ->
                { c
                    | username = input
                    , usernameIsAvailable = Loading
                    , usernameIsValid = True
                }
            )
        |> Return.command
            (CheckIfUsernameIsAvailable
                |> Debouncing.usernameAvailability.provideInput
                |> Return.task
            )


gotUsernameAvailability : { available : Bool, valid : Bool } -> Manager
gotUsernameAvailability { available, valid } =
    adjustSignUpContext_
        (\c ->
            if c.usernameIsAvailable /= Loading then
                c

            else if not valid then
                { c | usernameIsValid = False }

            else
                { c
                    | usernameIsAvailable = Success available
                    , usernameIsValid = True
                }
        )


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



-- ⚗️


adjustSignUpContext_ : (SignUpContext -> SignUpContext) -> Manager
adjustSignUpContext_ modifier model =
    case model.route of
        Routing.CreateAccount context ->
            Return.singleton { model | route = Routing.CreateAccount (modifier context) }

        _ ->
            Return.singleton model
