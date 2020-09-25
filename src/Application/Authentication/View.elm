module Authentication.View exposing (..)

import Common
import Common.View as Common
import Common.View.Footer as Footer
import Common.View.Svg
import Html exposing (Html)
import Html.Events as E
import Html.Events.Extra as E
import Html.Extra as Html
import Radix exposing (..)
import Styling as S
import Tailwind as T



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
        , createAccount model
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
    , Html.text "Sign in with Fission"
    ]
        |> Html.div
            [ T.flex
            , T.items_center
            , T.pt_px
            ]
        |> List.singleton
        |> S.button
            [ E.onClick RedirectToLobby
            , T.bg_purple
            , T.mt_8
            , T.mx_auto
            , T.text_sm
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
