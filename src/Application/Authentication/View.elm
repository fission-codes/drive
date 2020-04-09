module Authentication.View exposing (..)

import Authentication.Types exposing (..)
import Common exposing (ifThenElse)
import Common.View as Common
import Common.View.Footer as Footer
import Common.View.Svg
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra as E
import Html.Extra as Html
import Maybe.Extra as Maybe
import Routing
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🏔


aboutFissionDrive : List (Html Msg)
aboutFissionDrive =
    [ Html.text "Fission Drive is your web native file system. "
    , Html.br [ T.hidden, T.sm__block ] []
    , Html.text "Your files, under your control, available everywhere."
    ]



-- 🖼


notAuthenticated : Model -> Html Msg
notAuthenticated model =
    centered
        model
        [ Common.introLogo
        , Common.introText aboutFissionDrive

        --
        , Html.div
            [ T.flex, T.mt_8 ]
            [ S.buttonLink
                [ A.href (Routing.routeUrl Routing.createAccount model.url)

                --
                , T.bg_purple
                , T.flex
                , T.items_center
                ]
                [ Html.span
                    [ T.mr_2
                    , T.opacity_30
                    , T.text_white
                    , T.w_4
                    ]
                    [ Common.View.Svg.icon
                        { gradient = Nothing }
                    ]

                --
                , Html.text "Create an account"
                ]

            --
            , S.button
                [ T.bg_gray_200
                , T.ml_3
                , T.opacity_25
                , T.pointer_events_none
                ]
                [ Html.text "Sign in" ]
            ]
        ]



-- SIGN IN


signIn : Html Msg
signIn =
    -- TODO
    Html.nothing



-- SIGN UP


signUp : SignUpContext -> Model -> Html Msg
signUp context model =
    centered
        model
        [ Common.introLogo
        , Common.introText aboutFissionDrive

        --
        , Html.form
            [ E.onSubmit (CreateAccount context)

            --
            , T.max_w_sm
            , T.mt_8
            , T.text_left
            , T.w_full
            ]
            [ -- Email
              --------
              S.label
                [ A.for "email"
                ]
                [ Html.text "Email" ]
            , S.textField
                [ A.id "email"
                , A.placeholder "doctor@who.tv"
                , A.required True
                , A.type_ "email"
                , A.value context.email
                , E.onInput GotSignUpEmailInput
                ]
                []

            -- Username
            -----------
            , S.label
                [ A.for "username"
                , T.mt_6
                ]
                [ Html.text "Username" ]
            , S.textField
                [ A.id "username"
                , A.placeholder "thedoctor"
                , A.required True
                , A.value context.username
                , E.onInput GotSignUpUsernameInput
                ]
                []
            , usernameMessage context

            -- Sign Up
            ----------
            , let
                usernameIsAvailable =
                    Maybe.withDefault True context.usernameIsAvailable
              in
              S.button
                [ T.block
                , T.mt_6
                , T.w_full

                --
                , ifThenElse usernameIsAvailable T.bg_purple T.bg_dark_pink

                -- , ifThenElse usernameIsAvailable T.bg_purple T.bg_dark_pink
                ]
                [ Html.text "Get started" ]

            --
            , [ Html.text "Can I sign in instead?" ]
                |> Html.a
                    [ A.href "#/account/link"

                    --
                    , T.italic
                    , T.text_center
                    , T.text_gray_300
                    , T.text_sm
                    , T.underline
                    ]
                |> List.singleton
                |> Html.div
                    [ T.mt_3
                    , T.text_center
                    ]
            ]
        ]


usernameMessage : SignUpContext -> Html Msg
usernameMessage { username, usernameIsAvailable } =
    let
        checking =
            Maybe.isNothing usernameIsAvailable

        isAvailable =
            Maybe.withDefault True usernameIsAvailable

        noUsername =
            String.trim username == ""
    in
    Html.div
        [ T.items_center
        , T.leading_tight
        , T.mt_3
        , T.opacity_75
        , T.rounded
        , T.text_tiny
        , T.tracking_tight

        --
        , ifThenElse noUsername T.hidden T.flex
        , ifThenElse isAvailable T.text_inherit T.text_dark_pink
        , ifThenElse isAvailable T.dark__text_inherit T.dark__text_pink_tint
        ]
        [ FeatherIcons.globe
            |> FeatherIcons.withSize 16
            |> Common.wrapIcon [ T.mr_2, T.opacity_60 ]

        --
        , if noUsername then
            Html.nothing

          else if checking then
            Html.text "Checking if username is available ..."

          else if isAvailable then
            Html.span
                []
                [ Html.span [ T.antialiased ] [ Html.text "Your personal Drive address will be " ]
                , Html.strong [ T.break_all ] [ Html.text username, Html.text ".fission.name" ]
                ]

          else
            Html.span
                []
                [ Html.span [ T.antialiased ] [ Html.text "The username " ]
                , Html.strong [ T.break_all ] [ Html.text username ]
                , Html.span [ T.antialiased ] [ Html.text " is sadly not available." ]
                ]
        ]



-- LAYOUTS


centered : Model -> List (Html Msg) -> Html Msg
centered model nodes =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen
        ]
        [ Html.div
            [ S.container_padding
            , T.flex
            , T.flex_auto
            , T.flex_col
            , T.items_center
            , T.justify_center
            , T.py_12
            , T.text_center
            ]
            nodes

        --
        , Footer.view model
        ]
