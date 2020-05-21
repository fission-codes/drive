module Authentication.View exposing (..)

import Authentication.External exposing (createAccountUrl)
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
import Mode
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
            [ case model.mode of
                Mode.Default ->
                    createAccount model

                Mode.PersonalDomain ->
                    Html.nothing

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


createAccount : Model -> Html Msg
createAccount model =
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
        |> Html.div
            [ T.flex
            , T.items_center
            , T.pt_px
            ]
        |> List.singleton
        |> S.buttonLink
            [ A.href (createAccountUrl model.didKey model.url)
            , T.bg_purple
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
