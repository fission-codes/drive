module Common.View.ContextMenu exposing (view)

import Common
import ContextMenu exposing (..)
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra as E
import Html.Extra as Html
import Json.Decode
import Tailwind as T
import Types exposing (Msg(..))



-- 🖼


view : ContextMenu Msg -> Html Msg
view contextMenu =
    let
        { hook, items, coordinates } =
            ContextMenu.properties contextMenu
    in
    Html.div
        [ A.style "left" (String.fromFloat coordinates.x ++ "px")
        , A.style "top" (String.fromFloat coordinates.y ++ "px")

        --
        , A.style "min-width" "170px"

        --
        , T.bg_gray_900
        , T.fixed
        , T.leading_relaxed
        , T.overflow_hidden
        , T.rounded
        , T.shadow_md
        , T.select_none
        , T.text_gray_200
        , T.text_tiny
        , T.transform
        , T.z_50

        -- X
        , case hook of
            BottomCenter ->
                T.neg_translate_x_1over2

            TopCenterWithoutOffset ->
                T.neg_translate_x_1over2

            TopRight ->
                T.neg_translate_x_full

        -- Y
        , case hook of
            BottomCenter ->
                T.neg_translate_y_full

            TopCenterWithoutOffset ->
                T.translate_y_0

            TopRight ->
                T.translate_y_0

        -- Dark mode
        ------------
        , T.dark__bg_darkness_above
        , T.dark__text_gray_400
        ]
        (List.map
            (\item ->
                case item of
                    Item i ->
                        itemView i

                    Divider ->
                        Html.div
                            [ T.bg_gray_600
                            , T.h_px
                            , T.overflow_hidden
                            , T.pt_px

                            -- Dark mode
                            ------------
                            , T.dark__bg_white_05
                            ]
                            []
            )
            items
        )


itemView : ContextMenu.ItemProperties Msg -> Html Msg
itemView { icon, label, href, msg, active } =
    (case href of
        Just _ ->
            Html.a

        Nothing ->
            Html.div
    )
        (List.append
            itemClasses
            (case ( href, msg ) of
                ( Just h, _ ) ->
                    [ A.href h
                    , A.rel "noopener noreferrer"
                    , A.target "_blank"
                    ]

                ( _, Just m ) ->
                    [ E.onClick m ]

                ( Nothing, Nothing ) ->
                    []
            )
        )
        [ Html.span
            []
            [ icon
                |> FeatherIcons.withSize 16
                |> FeatherIcons.toHtml []
            ]
        , Html.span
            [ T.ml_2
            , T.pl_1
            ]
            [ Html.text label ]
        ]


itemClasses =
    [ T.border_b
    , T.border_gray_600
    , T.cursor_pointer
    , T.flex
    , T.items_center
    , T.pl_4
    , T.pr_12
    , T.py_4
    , T.truncate

    --
    , T.last__border_b_0

    -- Dark mode
    ------------
    , T.dark__border_white_05
    ]
