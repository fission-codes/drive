module Drive.View.Details exposing (view)

import Common
import Common.View as Common
import ContextMenu
import Drive.ContextMenu
import Drive.Item exposing (Item, Kind(..))
import Drive.View.Common as Drive
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra.Mouse as M
import Html.Extra as Html
import List.Extra as List
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
view : Bool -> Time.Posix -> Bool -> Bool -> Item -> Html Msg
view isGroundFloor currentTime expandSidebar showPreviewOverlay item =
    Html.div
        []
        [ overlay isGroundFloor currentTime expandSidebar showPreviewOverlay item
        , dataContainer item
        , extra item
        ]



-- OVERLAY


overlay : Bool -> Time.Posix -> Bool -> Bool -> Item -> Html Msg
overlay isGroundFloor currentTime expandSidebar showPreviewOverlay item =
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
            Drive.Item.Audio ->
                []

            Drive.Item.Video ->
                [ T.hidden ]

            Drive.Item.Image ->
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
            (overlayContents isGroundFloor currentTime item)

        --
        , Html.div
            [ T.absolute
            , T.bg_gray_900
            , T.inset_0
            , T.z_0

            --
            , case item.kind of
                Drive.Item.Image ->
                    T.opacity_80

                _ ->
                    T.opacity_100

            -- Dark mode
            ------------
            , T.dark__bg_darkness_below
            ]
            []

        --
        , Drive.sidebarControls
            { above = True
            , expanded = expandSidebar
            }
        ]


overlayContents : Bool -> Time.Posix -> Item -> List (Html Msg)
overlayContents isGroundFloor currentTime item =
    let
        isPublicRootDir =
            isGroundFloor && item.name == "public"
    in
    [ (if isPublicRootDir then
        FeatherIcons.globe

       else
        Drive.Item.kindIcon item.kind
      )
        |> FeatherIcons.withSize 128
        |> FeatherIcons.withStrokeWidth 0.5
        |> Common.wrapIcon
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
        [ if isPublicRootDir then
            Html.text "Public"

          else
            Html.text item.name
        ]

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
                Html.text (Drive.Item.kindName item.kind)

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
        [ Html.span
            [ case item.kind of
                Directory ->
                    { item = item
                    , presentable = True
                    }
                        |> CopyPublicUrl
                        |> E.onClick

                _ ->
                    E.onClick (DownloadItem item)

            --
            , T.antialiased
            , T.bg_purple
            , T.cursor_pointer
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
                [ case item.kind of
                    Directory ->
                        Html.text "Copy Link"

                    _ ->
                        Html.text "Download"
                ]
            ]

        --
        , Html.button
            [ item
                |> Drive.ContextMenu.item
                    ContextMenu.BottomCenter
                    { isGroundFloor = isGroundFloor }
                |> ShowContextMenu
                |> M.onClick

            --
            , T.appearance_none
            , T.ml_3
            , T.text_purple
            ]
            [ FeatherIcons.moreVertical
                |> FeatherIcons.withSize 18
                |> Common.wrapIcon [ T.pointer_events_none ]
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
                Drive.Item.Audio ->
                    [ T.mt_8
                    , T.relative
                    , T.text_center
                    , T.z_10
                    ]

                Drive.Item.Image ->
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
            Drive.Item.Image ->
                Html.nothing

            _ ->
                Common.loadingAnimation { size = S.iconSize }
        ]



-- OTHER BITS


extra : Item -> Html Msg
extra item =
    Html.div
        []
        [ case item.kind of
            Drive.Item.Image ->
                Html.div
                    [ T.absolute
                    , T.left_1over2
                    , T.leading_none
                    , T.neg_translate_x_1over2
                    , T.neg_translate_y_1over2
                    , T.top_1over2
                    , T.transform
                    , T.z_0
                    ]
                    [ Common.loadingAnimation { size = S.iconSize } ]

            _ ->
                Html.nothing
        ]
