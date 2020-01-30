module View.Common.Footer exposing (view)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🖼


view model =
    Html.footer
        [ T.bg_gray_600
        , T.pt_px
        ]
        [ Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.items_center
            , T.mx_auto
            , T.mt_px
            , T.py_8
            ]
            [ left

            --
            , Html.div [ T.flex_auto ] []

            --
            , right model
            ]
        ]



-- ㊙️


left =
    Html.div
        [ T.flex, T.items_center ]
        [ -----------------------------------------
          -- Logo
          -----------------------------------------
          Html.img
            [ A.src "images/badge-solid-faded.svg"
            , A.width 28
            ]
            []

        -----------------------------------------
        -- App name
        -----------------------------------------
        , Html.span
            [ T.font_display
            , T.font_medium
            , T.ml_3
            , T.pl_px
            , T.text_gray_300
            , T.text_sm
            , T.tracking_wider
            , T.uppercase
            ]
            [ Html.text "Fission Drive" ]
        ]


right model =
    Html.div
        [ T.flex
        , T.items_center
        , T.text_gray_300
        ]
        [ case model.rootCid of
            Just _ ->
                action
                    [ E.onClick Reset, T.cursor_pointer ]
                    FeatherIcons.hash
                    [ Html.text "Change CID" ]

            Nothing ->
                Html.text ""

        --
        , action
            [ T.cursor_not_allowed, T.ml_6 ]
            FeatherIcons.helpCircle
            [ Html.text "Help" ]
        ]



-- 🛠


action : List (Html.Attribute Msg) -> FeatherIcons.Icon -> List (Html Msg) -> Html Msg
action attributes icon nodes =
    Html.span
        (List.append
            attributes
            [ T.inline_flex
            , T.items_center
            , T.tracking_tight
            ]
        )
        [ icon
            |> FeatherIcons.withSize S.iconSize
            |> FeatherIcons.toHtml []

        --
        , Html.span
            [ T.ml_2 ]
            nodes
        ]
