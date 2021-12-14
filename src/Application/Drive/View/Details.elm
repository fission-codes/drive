module Drive.View.Details exposing (view)

import Common
import Common.View as Common
import ContextMenu
import Drive.ContextMenu
import Drive.Item exposing (Item, Kind(..))
import Drive.Sidebar as Sidebar
import Drive.View.Common as Drive
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra.Mouse as M
import Html.Extra as Html
import List.Extra as List
import Radix exposing (..)
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Webnative.Path as Path exposing (Encapsulated, Path)



-- 🖼


{-| NOTE: This is positioned using `position: sticky` and using fixed px values. Kind of a hack, and should be done in a better way, but I haven't found one.
-}
view : Bool -> Bool -> Bool -> Time.Posix -> Bool -> Bool -> List Item -> Html Msg
view useFS isGroundFloor isSingleFileView currentTime expandSidebar showPreviewOverlay items =
    Html.div
        [ T.flex
        , T.flex_col
        ]
        [ overlay isGroundFloor isSingleFileView currentTime expandSidebar showPreviewOverlay items
        , dataContainer useFS items
        , extra items
        ]



-- OVERLAY


overlay : Bool -> Bool -> Time.Posix -> Bool -> Bool -> List Item -> Html Msg
overlay isGroundFloor isSingleFileView currentTime expandSidebar showPreviewOverlay items =
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
        (case List.map .kind items of
            [ Drive.Item.Audio ] ->
                []

            [ Drive.Item.Video ] ->
                [ T.hidden ]

            [ Drive.Item.Image ] ->
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
            (overlayContents isGroundFloor currentTime items)

        --
        , Html.div
            [ T.absolute
            , T.bg_base_50
            , T.inset_0
            , T.z_0

            --
            , case List.map .kind items of
                [ Drive.Item.Image ] ->
                    T.opacity_80

                _ ->
                    T.opacity_100

            -- Dark mode
            ------------
            , T.dark__bg_base_950
            ]
            []

        --
        , Drive.sidebarControls
            { above = True
            , controls =
                List.concat
                    [ Common.when (not isSingleFileView)
                        [ Drive.controlExpand { expanded = expandSidebar } ]
                    , [ Drive.controlClose ]
                    ]
            }
        ]


overlayContents : Bool -> Time.Posix -> List Item -> List (Html Msg)
overlayContents isGroundFloor currentTime items =
    let
        ( itemNames, itemKinds ) =
            List.foldr
                (\item ( n, k ) ->
                    ( item.name :: n
                    , item.kind :: k
                    )
                )
                ( [], [] )
                items

        isPublicRootDir =
            isGroundFloor && itemNames == [ "public" ]
    in
    [ -----------------------------------------
      -- Icon
      -----------------------------------------
      (if isPublicRootDir then
        FeatherIcons.globe

       else
        case items of
            [ item ] ->
                Drive.Item.kindIcon item.kind

            _ ->
                FeatherIcons.copy
      )
        |> FeatherIcons.withSize 128
        |> FeatherIcons.withStrokeWidth 0.5
        |> Common.wrapIcon
            [ T.flex
            , T.flex_col
            , T.items_center
            ]

    -----------------------------------------
    -- Title
    -----------------------------------------
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
            case items of
                [ item ] ->
                    Html.text item.name

                _ ->
                    [ String.fromInt (List.length items)
                    , "items"
                    ]
                        |> String.join " "
                        |> Html.text
        ]

    -----------------------------------------
    -- Subtitle
    -----------------------------------------
    , Html.div
        [ T.mt_px
        , T.text_center
        , T.text_base_500
        , T.text_sm
        ]
        [ case items of
            [ item ] ->
                case ( item.posixTime, item.size ) of
                    ( Just time, _ ) ->
                        Html.text (Time.Distance.inWords currentTime time)

                    ( Nothing, 0 ) ->
                        -- TODO: Show amount of items the directory has
                        Html.text (Drive.Item.kindName item.kind)

                    ( Nothing, size ) ->
                        Html.text (Common.sizeInWords size)

            _ ->
                Html.text ""
        ]

    -----------------------------------------
    -- Actions
    -----------------------------------------
    , Html.div
        [ T.flex
        , T.items_center
        , T.justify_center
        , T.mt_5
        ]
        (case items of
            [] ->
                []

            [ item ] ->
                overlaySingleItemActions isGroundFloor item

            _ :: _ ->
                overlayMultipleItemActions items
        )
    ]


overlaySingleItemActions : Bool -> Item -> List (Html Msg)
overlaySingleItemActions isGroundFloor item =
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
        , T.text_base_50
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


overlayMultipleItemActions : List Item -> List (Html Msg)
overlayMultipleItemActions items =
    [ Html.button
        [ ContextMenu.BottomCenter
            |> Drive.ContextMenu.selection
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



-- DATA


dataContainer : Bool -> List Item -> Html Msg
dataContainer useFS items =
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

        kinds =
            List.map .kind items
    in
    (case ( kinds, items ) of
        ( [ Directory ], _ ) ->
            Html.div

        ( _, [ item ] ) ->
            fissionDriveMedia
                { name = item.name
                , path = item.path
                , useFS = useFS
                }

        _ ->
            Html.div
    )
        (List.append
            [ A.class "drive-item__preview" ]
            (case kinds of
                [ Drive.Item.Audio ] ->
                    [ T.mt_8
                    , T.relative
                    , T.text_center
                    , T.z_10
                    ]

                [ Drive.Item.Image ] ->
                    List.append
                        defaultStyles
                        [ E.onClick (SidebarMsg Sidebar.DetailsShowPreviewOverlay)
                        , T.cursor_pointer
                        ]

                _ ->
                    defaultStyles
            )
        )
        []



-- OTHER BITS


extra : List Item -> Html Msg
extra item =
    Html.div
        []
        [ case List.map .kind item of
            [ Drive.Item.Image ] ->
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



-- Custom Element (see media.js)


fissionDriveMedia : { name : String, path : Path Encapsulated, useFS : Bool } -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
fissionDriveMedia { name, path, useFS } attributes children =
    let
        stringFromBool b =
            if b then
                "true"

            else
                "false"
    in
    Html.node "fission-drive-media"
        (List.append
            [ A.attribute "name" name
            , A.attribute "path" (Path.toPosix path)
            , A.attribute "useFS" (stringFromBool useFS)
            ]
            attributes
        )
        children
