module Common.View.Footer exposing (view)

import Explore.Types as Explore
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ipfs
import Maybe.Extra as Maybe
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🖼


view : Model -> Html Msg
view m =
    Html.footer
        [ T.bg_gray_900
        , T.pt_px

        -- Dark mode
        ------------
        , T.dark__bg_darkness_below
        ]
        [ Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.items_center
            , T.mx_auto
            , T.mt_px
            , T.overflow_hidden
            , T.py_8
            ]
            [ left

            --
            , Html.div
                [ T.flex_auto, T.hidden, T.md__block ]
                []

            --
            , right m
            ]
        ]



-- ㊙️


left : Html Msg
left =
    Html.div
        [ T.hidden
        , T.items_center

        --
        , T.md__flex
        ]
        [ -----------------------------------------
          -- Logo
          -----------------------------------------
          Html.img
            [ A.src "images/badge-solid-faded.svg"
            , A.width 28

            --
            , T.opacity_70
            ]
            []

        -----------------------------------------
        -- App name
        -----------------------------------------
        , Html.span
            [ T.font_display
            , T.font_medium
            , T.leading_tight
            , T.ml_3
            , T.pl_px
            , T.text_gray_400
            , T.text_sm
            , T.tracking_wider
            , T.uppercase
            ]
            [ Html.text "Fission Drive" ]
        ]


right : Model -> Html Msg
right model =
    Html.div
        [ T.flex
        , T.items_center
        , T.origin_left
        , T.scale_90
        , T.text_gray_300
        , T.transform

        --
        , T.sm__scale_100
        ]
        [ if model.ipfs == Ipfs.Ready && Maybe.isJust model.rootCid then
            action
                Button
                [ E.onClick (ExploreMsg Explore.Reset), T.cursor_pointer ]
                FeatherIcons.hash
                [ Html.text "Change CID" ]

          else
            Html.text ""

        --
        , action
            Link
            [ A.href "https://fission.codes/support"
            , A.target "_blank"
            ]
            FeatherIcons.lifeBuoy
            [ Html.text "Support" ]

        --
        , action
            Link
            [ A.href "https://guide.fission.codes/drive"
            , A.target "_blank"
            ]
            FeatherIcons.book
            [ Html.text "Guide" ]
        ]



-- 🛠


type Action
    = Button
    | Link


action : Action -> List (Html.Attribute Msg) -> FeatherIcons.Icon -> List (Html Msg) -> Html Msg
action a attributes icon nodes =
    (case a of
        Button ->
            Html.span

        Link ->
            Html.a
    )
        (List.append
            attributes
            [ T.inline_flex
            , T.items_center
            , T.leading_tight
            , T.ml_8
            , T.tracking_tight

            --
            , T.first__ml_0
            ]
        )
        [ icon
            |> FeatherIcons.withSize S.iconSize
            |> FeatherIcons.toHtml []

        --
        , Html.span
            [ T.ml_2, T.truncate ]
            nodes
        ]
