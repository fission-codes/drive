module Drive.View.Details exposing (view)

import Common
import Common.View as Common
import Common.View.Footer as Footer
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html exposing (nothing)
import Html.Lazy
import Item exposing (Item, Kind(..))
import List.Extra as List
import Maybe.Extra as Maybe
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Types exposing (..)
import Url.Builder



-- 🖼


{-| NOTE: This is positioned using `position: sticky` and using fixed px values. Kind of a hack, and should be done in a better way, but I haven't found one.
-}
view : Time.Posix -> String -> Bool -> Bool -> Item -> Html Msg
view currentTime base largePreview showPreviewOverlay item =
    let
        publicUrl =
            Item.publicUrl base item
    in
    Html.div
        []
        [ overlay currentTime publicUrl largePreview showPreviewOverlay item
        , dataContainer item
        , extra item
        ]



-- OVERLAY


overlay : Time.Posix -> String -> Bool -> Bool -> Item -> Html Msg
overlay currentTime publicUrl largePreview showPreviewOverlay item =
    let
        defaultAttributes =
            [ T.absolute
            , S.default_transition_duration
            , S.default_transition_easing
            , T.flex
            , T.flex_col
            , T.inset_0
            , T.items_center
            , T.justify_center
            , T.px_4
            , T.transition_opacity
            , T.transform
            , T.translate_x_0
            , T.z_20
            ]
    in
    Html.div
        (case item.kind of
            Item.Audio ->
                []

            Item.Video ->
                [ T.hidden ]

            Item.Image ->
                List.append
                    defaultAttributes
                    (if showPreviewOverlay then
                        []

                     else
                        [ T.opacity_0
                        , T.pointer_events_none
                        , T.group_hover__opacity_100
                        , T.group_hover__pointer_events_auto
                        ]
                    )

            _ ->
                defaultAttributes
        )
        [ Html.div
            [ T.max_w_full
            , T.relative
            , T.z_10
            ]
            (overlayContents currentTime publicUrl item)

        --
        , Html.div
            [ T.absolute
            , T.bg_gray_900
            , T.inset_0
            , T.z_0

            --
            , case item.kind of
                Item.Image ->
                    T.opacity_80

                _ ->
                    T.opacity_100

            -- Dark mode
            ------------
            , T.dark__bg_darkness_below
            ]
            []

        --
        , actions largePreview
        ]


overlayContents : Time.Posix -> String -> Item -> List (Html Msg)
overlayContents currentTime publicUrl item =
    [ item.kind
        |> Item.kindIcon
        |> FeatherIcons.withSize 128
        |> FeatherIcons.withStrokeWidth 0.5
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div
            [ T.flex
            , T.flex_col
            , T.items_center
            ]

    --
    , Html.div
        [ T.font_semibold
        , T.mt_1
        , T.text_center
        , T.tracking_tight
        , T.truncate
        ]
        [ Html.text item.name ]

    --
    , Html.div
        [ T.mt_px
        , T.text_center
        , T.text_gray_300
        , T.text_sm
        ]
        [ case ( item.posixTime, item.size ) of
            ( Just time, _ ) ->
                Html.text (Time.Distance.inWords currentTime time)

            ( Nothing, 0 ) ->
                -- TODO: Show amount of items the directory has
                Html.text (Item.kindName item.kind)

            ( Nothing, size ) ->
                Html.text (Common.sizeInWords size)
        ]

    --
    , Html.div
        [ T.flex
        , T.items_center
        , T.justify_center
        , T.mt_5
        ]
        [ Html.a
            [ A.href publicUrl
            , A.target "_blank"

            --
            , T.antialiased
            , T.bg_purple
            , T.font_semibold
            , T.inline_block
            , T.px_2
            , T.py_1
            , T.rounded
            , T.text_gray_900
            , T.text_sm
            , T.tracking_wider
            , T.uppercase
            ]
            [ Html.span
                [ T.block, T.pt_px ]
                [ Html.text "Open in new tab" ]
            ]

        --
        , Html.button
            [ E.onClick (CopyLink item)

            --
            , T.appearance_none
            , T.ml_3
            , T.text_purple
            ]
            [ FeatherIcons.share
                |> FeatherIcons.withSize 18
                |> FeatherIcons.toHtml []
            ]
        ]
    ]



-- DATA


dataContainer : Item -> Html Msg
dataContainer item =
    let
        defaultStyles =
            [ T.absolute
            , T.flex
            , T.inset_0
            , T.items_center
            , T.justify_center
            , T.text_center
            , T.z_10
            ]
    in
    Html.div
        (List.append
            [ A.id item.id
            , A.class "drive-item__preview"
            ]
            (case item.kind of
                Item.Audio ->
                    [ T.mt_8
                    , T.relative
                    , T.text_center
                    , T.z_10
                    ]

                Item.Image ->
                    List.append
                        defaultStyles
                        [ E.onClick ShowPreviewOverlay
                        , T.cursor_pointer
                        ]

                _ ->
                    defaultStyles
            )
        )
        [ case item.kind of
            Item.Image ->
                Html.nothing

            _ ->
                Common.loadingAnimation
        ]



-- OTHER BITS


extra : Item -> Html Msg
extra item =
    Html.div
        [ T.relative
        , T.z_0
        ]
        [ case item.kind of
            Item.Image ->
                Common.loadingAnimation

            _ ->
                Html.nothing
        ]


actions : Bool -> Html Msg
actions largePreview =
    Html.div
        [ T.absolute
        , S.default_transition_duration
        , S.default_transition_easing
        , T.flex
        , T.items_center
        , T.justify_end
        , T.left_0
        , T.mt_px
        , T.opacity_0
        , T.px_2
        , T.pt_px
        , T.right_0
        , T.text_gray_300
        , T.text_sm
        , T.top_0
        , T.transition
        , T.transition_opacity
        , T.z_30

        --
        , T.group_hover__opacity_100
        ]
        [ Html.div
            [ T.absolute
            , T.border_b
            , T.border_gray_300
            , T.left_0
            , T.opacity_10
            , T.top_full
            , T.right_0
            ]
            []

        --
        , Html.div
            [ E.onClick ToggleLargePreview

            --
            , T.cursor_pointer
            , T.hidden
            , T.items_center
            , T.px_2
            , T.py_3

            --
            , T.md__flex
            ]
            [ (if largePreview then
                FeatherIcons.minimize2

               else
                FeatherIcons.maximize2
              )
                |> FeatherIcons.withSize 14
                |> FeatherIcons.toHtml [ A.style "margin" "0 auto" ]
                |> List.singleton
                |> Html.div [ T.flex_shrink_0, T.w_6 ]

            --
            , Html.div
                [ T.ml_1 ]
                [ if largePreview then
                    Html.text "Minimize"

                  else
                    Html.text "Maximize"
                ]
            ]

        --
        , Html.div
            [ E.onClick RemoveSelection

            --
            , T.cursor_pointer
            , T.flex
            , T.items_center
            , T.px_2
            , T.py_3
            ]
            [ FeatherIcons.x
                |> FeatherIcons.withSize 18
                |> FeatherIcons.toHtml [ A.style "margin" "0 auto" ]
                |> List.singleton
                |> Html.div [ T.flex_shrink_0, T.w_6 ]

            --
            , Html.div
                [ T.ml_1 ]
                [ Html.text "Close" ]
            ]
        ]
