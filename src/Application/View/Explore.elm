module View.Explore exposing (view)

import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ipfs
import Styling as S
import Tailwind as T
import Types exposing (..)
import View.Common as Common
import View.Common.Footer as Footer



-- 🖼


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
        [ S.container_padding
        , T.flex
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
                This is a prototype which'll later evolve into your personal Fission Drive. For now though, you can use it to browse through IPFS content. Put an IPFS Hash below and explore.
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
                , A.value m.exploreInput
                , E.onInput GotExploreInput

                --
                , case m.ipfs of
                    Ipfs.Error _ ->
                        T.border_pink_tint

                    _ ->
                        T.border_gray_500

                --
                , T.appearance_none
                , T.bg_transparent
                , T.border_2
                , T.border_gray_500
                , T.flex_auto
                , T.px_6
                , T.py_3
                , T.rounded_full
                , T.text_lg
                , T.w_0

                --
                , case m.ipfs of
                    Ipfs.Error _ ->
                        T.focus__border_dark_pink

                    _ ->
                        T.focus__border_purple_tint
                ]
                []

            --
            , Html.button
                [ case m.ipfs of
                    Ipfs.Connecting ->
                        E.onClick Bypass

                    Ipfs.Listing ->
                        E.onClick Reset

                    _ ->
                        E.onClick Explore

                --
                , case m.ipfs of
                    Ipfs.Error _ ->
                        T.bg_dark_pink

                    _ ->
                        T.bg_purple

                --
                , T.antialiased
                , T.appearance_none
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
                [ case m.ipfs of
                    Ipfs.Listing ->
                        Common.loadingAnimation

                    _ ->
                        Html.span [ T.block, T.mt_px ] [ Html.text "Explore" ]
                ]
            ]
        ]
