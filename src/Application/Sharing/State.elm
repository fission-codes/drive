module Sharing.State exposing (..)

import Browser.Dom as Dom
import Common.State as Common
import Debouncing
import Dict
import Drive.Item exposing (Item)
import Drive.Modals as Modals
import Http
import Ports
import Radix exposing (..)
import Result.Extra as Result
import Return exposing (return)
import Return.Extra as Return
import Task
import Url
import Webnative.Path as Path



-- 📣


checkUsernameExistanceForSharingWhenSettled : String -> Manager
checkUsernameExistanceForSharingWhenSettled u model =
    let
        username =
            String.trim u

        ( uKey, vKey ) =
            ( Modals.shareItemStateKeys.username
            , Modals.shareItemStateKeys.isValidUsername
            )
    in
    (case username of
        "" ->
            Return.singleton model

        _ ->
            username
                |> CheckUsernameExistanceForSharing
                |> Debouncing.usernameLookup.provideInput
                |> Return.task
                |> return model
    )
        |> Return.andThen (Common.setModalState uKey username)
        |> Return.andThen (Common.setModalState vKey Modals.void)


checkUsernameExistanceForSharing : String -> Manager
checkUsernameExistanceForSharing username model =
    { url =
        model.apiEndpoint ++ "/v2/api/user/data/" ++ Url.percentEncode username
    , expect =
        Http.expectString
            (\result ->
                result
                    |> Result.unwrap
                        Modals.booleans.false
                        (always Modals.booleans.true)
                    |> SetModalState
                        Modals.shareItemStateKeys.isValidUsername
            )
    }
        |> Http.get
        |> return model


gotFsShareError : String -> Manager
gotFsShareError error model =
    let
        keys =
            Modals.shareItemStateKeys

        states =
            Modals.shareItemShareStates
    in
    model
        |> Return.singleton
        |> Return.andThen
            (Common.setModalState keys.sharingError error)
        |> Return.andThen
            (Common.setModalState keys.sharingState states.sharingFailed)


gotFsShareLink : String -> Manager
gotFsShareLink link model =
    let
        keys =
            Modals.shareItemStateKeys

        states =
            Modals.shareItemShareStates
    in
    model
        |> Return.singleton
        |> Return.andThen
            (Common.setModalState keys.sharingLink link)
        |> Return.andThen
            (Common.setModalState keys.sharingState states.sharingSucceeded)


shareItem : Item -> Manager
shareItem item model =
    let
        ( uKey, sKey, states ) =
            ( Modals.shareItemStateKeys.username
            , Modals.shareItemStateKeys.sharingState
            , Modals.shareItemShareStates
            )
    in
    case Maybe.andThen (\m -> Dict.get uKey m.state) model.modal of
        Just username ->
            { path = Path.encode item.path
            , shareWith = username
            }
                |> Ports.fsShareItem
                |> return model
                |> Return.andThen
                    (Common.setModalState sKey states.creatingShare)

        Nothing ->
            Return.singleton model


showShareItemModal : Item -> Manager
showShareItemModal item model =
    return
        { model | modal = Just (Modals.shareItem item) }
        (Task.attempt (\_ -> Bypass) <| Dom.focus "modal__share-item__input")
