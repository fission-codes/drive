module Drive.Modals exposing (booleans, renameItem, shareItem, shareItemShareStates, shareItemStateKeys, void)

import Common.View as Common
import Dict
import Dict.Ext as Dict
import Drive.Item as Item exposing (Item, Kind(..))
import FeatherIcons
import Html
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Modal exposing (Modal)
import Radix exposing (Msg(..))
import Styling as S
import Tailwind as T



-- 🌳


booleans =
    { false = "f"
    , true = "t"
    }


boolFromString : String -> Maybe Bool
boolFromString string =
    case String.toLower string of
        "f" ->
            Just False

        "t" ->
            Just True

        _ ->
            Nothing


void =
    ""



-- ⚗️


renameItem : Item -> Modal Msg
renameItem item =
    { confirmationButtons =
        \state ->
            [ confirmationButton { enabled = True } [ Html.text "Rename" ]
            , cancelButton "Cancel"
            ]
    , content =
        \state ->
            [ S.textField
                [ A.id "modal__rename-item__input"
                , A.placeholder "Name"
                , A.value item.name
                , E.onInput (SetModalState "name")

                --
                , T.max_w_xs
                , T.w_screen
                ]
                []
            ]
    , onSubmit =
        RenameItem item
    , state =
        Dict.empty
    , title =
        case item.kind of
            Directory ->
                "Rename directory"

            _ ->
                "Rename file"
    }


shareItem : Item -> Modal Msg
shareItem item =
    let
        ( usernameKey, isValidKey, stateKey ) =
            ( shareItemStateKeys.username
            , shareItemStateKeys.isValidUsername
            , shareItemStateKeys.sharingState
            )
    in
    { confirmationButtons =
        \state ->
            let
                sharingState =
                    Dict.fetch stateKey void state
            in
            if sharingState == shareItemShareStates.sharingSucceeded then
                -----------------------------------------
                -- Succeeded
                -----------------------------------------
                [ cancelButton "Close" ]

            else if Dict.fetch stateKey void state == shareItemShareStates.creatingShare then
                -----------------------------------------
                -- Creating ...
                -----------------------------------------
                [ confirmationButton
                    { enabled = False }
                    [ Common.loadingAnimationWithAttributes
                        [ T.mr_2
                        , T.text_opacity_60
                        , T.text_white
                        ]
                        { size = 15 }
                    , Html.text "Share"
                    ]
                , cancelButton "Cancel"
                ]

            else
                -----------------------------------------
                -- Otherwise
                -----------------------------------------
                [ confirmationButton
                    { enabled = True }
                    [ Html.text "Share" ]
                , cancelButton "Cancel"
                ]
    , content =
        \state ->
            let
                sharingState =
                    Dict.fetch stateKey void state
            in
            if sharingState == shareItemShareStates.sharingSucceeded then
                -----------------------------------------
                -- Succeeded
                -----------------------------------------
                [ Html.div
                    [ T.opacity_60
                    , T.text_center
                    , T.text_sm
                    ]
                    [ Html.text "The "
                    , case item.kind of
                        Directory ->
                            Html.text "directory"

                        _ ->
                            Html.text "file"
                    , Html.text " will be available to "
                    , Html.span
                        []
                        [ Html.text (Dict.fetch usernameKey "username" state) ]
                    , Html.text " via the following link."
                    ]

                --
                , Html.div
                    [ A.style "width" "70vw"
                    , T.max_w_md
                    , T.mt_2
                    , T.relative
                    ]
                    [ S.textField
                        [ A.disabled True
                        , state
                            |> Dict.fetch shareItemStateKeys.sharingLink ""
                            |> A.value

                        --
                        , T.w_full
                        ]
                        []

                    --
                    , FeatherIcons.clipboard
                        |> FeatherIcons.withSize 16
                        |> Common.wrapIcon [ T.text_purple ]
                        |> List.singleton
                        |> Html.span
                            [ { clip = Dict.fetch shareItemStateKeys.sharingLink "" state
                              , notification = "Copied the share link to the clipboard"
                              }
                                |> CopyToClipboard
                                |> E.onClick

                            --
                            , A.style "box-shadow" "0 0 4px 4px currentColor"
                            , A.title "Copy to clipboard"

                            --
                            , T.absolute
                            , T.bg_base_50
                            , T.cursor_pointer
                            , T.mr_4
                            , T.neg_translate_y_1over2
                            , T.px_2
                            , T.py_1
                            , T.right_0
                            , T.text_base_50
                            , T.top_1over2
                            , T.transform

                            -- Dark mode
                            ------------
                            , T.dark__bg_base_800
                            , T.dark__text_base_800
                            ]
                    ]
                ]

            else
                -----------------------------------------
                -- Not succeeded
                -----------------------------------------
                [ Html.div
                    [ T.relative ]
                    [ S.textField
                        [ A.attribute "autocapitalize" "none"
                        , A.attribute "autocorrect" "off"
                        , A.attribute "spellcheck" "false"
                        , A.id "modal__share-item__input"
                        , A.placeholder "Fission Username"
                        , A.name "username"
                        , A.required True
                        , A.value (Dict.fetch usernameKey "" state)

                        --
                        , E.onInput CheckUsernameExistanceForSharingWhenSettled

                        --
                        , A.style "width" "70vw"
                        , T.max_w_sm
                        ]
                        []

                    --
                    , Html.div
                        [ T.absolute
                        , T.mr_4
                        , T.right_0
                        , T.top_1over2
                        , T.transform
                        , T.neg_translate_y_1over2
                        ]
                        [ case Dict.get shareItemStateKeys.isValidUsername state of
                            Just "f" ->
                                FeatherIcons.xCircle
                                    |> FeatherIcons.withSize 16
                                    |> Common.wrapIcon [ T.text_red ]

                            Just "t" ->
                                FeatherIcons.checkCircle
                                    |> FeatherIcons.withSize 16
                                    |> Common.wrapIcon [ T.text_green ]

                            _ ->
                                Html.nothing
                        ]
                    ]

                -- Possible error
                -----------------
                , case Dict.get shareItemStateKeys.sharingError state of
                    Nothing ->
                        Html.nothing

                    Just "" ->
                        Html.nothing

                    Just err ->
                        Html.div
                            [ T.flex
                            , T.items_center
                            , T.justify_center
                            , T.mt_2
                            , T.text_red
                            , T.text_sm
                            ]
                            [ FeatherIcons.alertTriangle
                                |> FeatherIcons.withSize 15
                                |> Common.wrapIcon [ T.mr_2 ]
                            , Html.div
                                []
                                [ Html.text err ]
                            ]
                ]
    , onSubmit =
        ShareItem item
    , state =
        Dict.fromList
            [ ( shareItemStateKeys.sharingState
              , shareItemShareStates.waitingForInput
              )
            , ( shareItemStateKeys.isValidUsername
              , void
              )
            ]
    , title =
        case item.kind of
            Directory ->
                "Share directory"

            _ ->
                "Share file"
    }


shareItemStateKeys =
    { isValidUsername = "isValidUsername"
    , sharingError = "sharingError"
    , sharingLink = "sharingLink"
    , sharingState = "sharingState"
    , username = "username"
    }


shareItemShareStates =
    { waitingForInput = "WAITING_FOR_INPUT"
    , creatingShare = "CREATING_SHARE"
    , sharingSucceeded = "SHARING_SUCCEEDED"
    , sharingFailed = "SHARING_FAILED"
    }



-- ㊙️


cancelButton text =
    S.button
        [ E.onClick HideModal

        --
        , T.bg_base_400
        , T.text_tiny

        -- Dark mode
        ------------
        , T.dark__bg_base_600
        ]
        [ Html.text text
        ]


confirmationButton { enabled } =
    S.button
        [ A.type_ "submit"
        , A.disabled (not enabled)

        --
        , T.bg_purple
        , T.inline_flex
        , T.items_center
        , T.text_tiny
        ]
