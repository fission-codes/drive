module View.Explore exposing (view)

import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Tailwind as T
import Types exposing (..)
import View.Common as Common
import View.Common.Footer as Footer


view : Model -> Html Msg
view model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen
        ]
        [ inputScreen model
        , Footer.view model
        ]



-- ㊙️


inputScreen : Model -> Html Msg
inputScreen m =
    Html.div
        [ T.flex
        , T.flex_auto
        , T.flex_col
        , T.items_center
        , T.justify_center
        , T.text_center
        ]
        [ Html.div
            [ T.antialiased
            , T.font_display
            , T.font_light
            , T.leading_tight
            , T.text_6xl
            , T.tracking_widest
            , T.uppercase
            ]
            [ Html.text "Fission Drive" ]

        --
        , Html.div
            [ T.max_w_md
            , T.mt_6
            ]
            [ Html.text """
                This is a prototype which later evolve into your personal Fission Drive. For now though, you can use it to browse through IPFS content. Put an IPFS Hash below and explore.
              """
            ]

        --
        , Html.div
            [ T.flex
            , T.max_w_lg
            , T.mt_8
            , T.w_full
            ]
            [ Html.input
                [ A.placeholder "QmPx36eeZypeZvfHgHo1H59udrhuJhMksg8PBvKn3B7JCA"
                , A.value (Maybe.withDefault "" m.exploreInput)
                , E.onInput GotExploreInput

                --
                , T.appearance_none
                , T.border_2
                , T.border_gray_500
                , T.flex_auto
                , T.px_6
                , T.py_3
                , T.rounded_full
                , T.text_lg

                --
                , T.focus__border_light_purple
                ]
                []

            --
            , Html.button
                [ case m.rootCid of
                    Just _ ->
                        E.onClick Bypass

                    Nothing ->
                        E.onClick Explore

                --
                , T.antialiased
                , T.appearance_none
                , T.bg_purple
                , T.font_semibold
                , T.ml_3
                , T.px_6
                , T.py_3
                , T.relative
                , T.rounded_full
                , T.text_sm
                , T.text_white
                , T.tracking_wider
                , T.uppercase

                --
                , T.focus__shadow_outline
                ]
                [ case m.rootCid of
                    Just _ ->
                        Common.loadingAnimation

                    Nothing ->
                        Html.text "Explore"
                ]
            ]
        ]
