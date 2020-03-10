module Explore.View exposing (view)

import Common
import Common.View as Common
import Common.View.Footer as Footer
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ipfs
import Json.Decode as Decode
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🖼


view : Model -> Html Msg
view model =
    Html.div
        [ E.on "focusout" (Decode.succeed Blurred)
        , E.on "focusin" (Decode.succeed Focused)

        --
        , T.flex
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
            , T.mt_5
            , T.text_gray_300

            -- Dark mode
            ------------
            , T.dark__text_gray_400
            ]
            [ Html.text """
                This is a Preview release which will evolve into your personal Fission Drive. Enter any public IPFS hash or use the example hash.
              """
            ]

        --
        , Html.form
            [ case m.ipfs of
                Ipfs.Connecting ->
                    E.onSubmit Bypass

                Ipfs.InitialListing ->
                    E.onSubmit Reset

                _ ->
                    E.onSubmit Explore

            --
            , T.flex
            , T.max_w_lg
            , T.mt_8
            , T.w_full
            ]
            [ Html.input
                [ A.placeholder Common.defaultCid
                , A.value (Maybe.withDefault "" m.exploreInput)
                , E.onInput GotInput

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
                , T.outline_none
                , T.px_6
                , T.py_3
                , T.rounded_full
                , T.text_inherit
                , T.text_lg
                , T.w_0

                --
                , case m.ipfs of
                    Ipfs.Error _ ->
                        T.focus__border_dark_pink

                    _ ->
                        T.focus__border_purple_tint

                -- Dark mode
                ------------
                , T.dark__border_gray_300

                --
                , case m.ipfs of
                    Ipfs.Error _ ->
                        T.dark__focus__border_dark_pink

                    _ ->
                        T.dark__focus__border_purple
                ]
                []

            --
            , Html.button
                [ case m.ipfs of
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
                    Ipfs.InitialListing ->
                        FeatherIcons.loader
                            |> FeatherIcons.withSize 24
                            |> FeatherIcons.toHtml []
                            |> List.singleton
                            |> Html.div
                                [ T.animation_spin
                                , T.text_purple_tint
                                ]

                    _ ->
                        Html.span
                            [ T.block, T.mt_px ]
                            [ Html.text "Explore" ]
                ]
            ]
        ]
