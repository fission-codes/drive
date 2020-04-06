module Authentication.View exposing (..)

import Authentication.Types exposing (..)
import Common.View as Common
import Common.View.Footer as Footer
import Common.View.Svg
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
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
        , Html.div
            [ T.max_w_md
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
                , A.type_ "email"
                , A.value context.email
                , E.onInput (AdjustSignUpContext signUpContextModifiers.email)
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
                , A.value context.username
                , E.onInput (AdjustSignUpContext signUpContextModifiers.username)
                ]
                []
            , usernameSuccess

            -- Sign Up
            ----------
            , S.button
                [ T.bg_purple
                , T.block
                , T.mt_6
                , T.w_full
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


signUpContextModifiers =
    { email = \c e -> { c | email = e }
    , username = \c u -> { c | username = u }
    }


usernameSuccess : Html Msg
usernameSuccess =
    Html.div
        [ T.flex
        , T.items_center
        , T.leading_tight
        , T.mt_3
        , T.opacity_75
        , T.rounded
        , T.text_tiny
        , T.tracking_tight
        ]
        [ FeatherIcons.globe
            |> FeatherIcons.withSize 16
            |> Common.wrapIcon [ T.mr_2, T.opacity_60 ]

        --
        , Html.span
            []
            [ Html.span [ T.antialiased ] [ Html.text "The " ]
            , Html.strong [ T.break_all ] [ Html.text "thedoctor.fission.name" ]
            , Html.span [ T.antialiased ] [ Html.text " domain will be at your command." ]
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
            , T.text_center
            ]
            nodes

        --
        , Footer.view model
        ]
