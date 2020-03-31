module Drive.View exposing (view)

import Common
import Common.View as Common
import Common.View.Footer as Footer
import Drive.ContextMenu as ContextMenu
import Drive.Item exposing (Item, Kind(..))
import Drive.Sidebar as Sidebar
import Drive.View.Sidebar as Sidebar
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra.Mouse as M
import Html.Extra as Html exposing (nothing)
import List.Extra as List
import Maybe.Extra as Maybe
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
import Url.Builder



-- 🖼


view : Model -> Html Msg
view model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen
        ]
        [ header model
        , content model

        --
        , Html.div
            [ T.bottom_0
            , T.left_0
            , T.sticky
            , T.right_0
            , T.z_10
            ]
            [ Footer.view model ]
        ]



-- HEADER


header : Model -> Html Msg
header model =
    let
        segments =
            Routing.treePathSegments model.route

        amountOfSegments =
            List.length segments
    in
    Html.header
        [ T.bg_gray_600
        , T.break_all
        , T.left_0
        , T.py_8
        , T.right_0
        , T.sticky
        , T.text_white
        , T.top_0
        , T.z_10

        -- Dark mode
        ------------
        , T.dark__bg_gray_100
        ]
        [ Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.items_center
            , T.mb_px
            , T.mx_auto
            , T.pb_px
            ]
            [ -----------------------------------------
              -- Icon
              -----------------------------------------
              FeatherIcons.hardDrive
                |> FeatherIcons.withSize S.iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.div
                    [ T.mr_5
                    , T.opacity_50
                    , T.text_purple
                    ]

            -----------------------------------------
            -- Path
            -----------------------------------------
            -- Tablet and bigger screens
            , let
                a =
                    toFloat (model.viewportSize.width - 208)

                b =
                    toFloat (String.length <| String.join " / " segments)

                showEntirePath =
                    a / b > 17.5
              in
              segments
                |> List.append [ "ROOT" ]
                |> List.reverse
                |> List.indexedMap
                    (\idx segment ->
                        if idx == 0 && amountOfSegments == 0 then
                            Just <| rootPathPart model segments

                        else if idx == 0 then
                            Just <| activePathPart (amountOfSegments - idx + 1) segment

                        else if showEntirePath && idx == amountOfSegments then
                            Just <| rootPathPart model segments

                        else if showEntirePath then
                            Just <| inactivePathPart (amountOfSegments - idx + 1) segment

                        else if idx == 1 then
                            Just <| inactivePathPart (amountOfSegments - idx + 1) "…"

                        else
                            Nothing
                    )
                |> List.filterMap identity
                |> List.reverse
                |> List.intersperse pathSeparator
                |> Html.div
                    [ T.flex_auto
                    , T.hidden
                    , T.italic
                    , T.leading_snug
                    , T.text_2xl
                    , T.tracking_tight

                    --
                    , T.md__block
                    ]

            -- Mobile
            , segments
                |> List.append [ "ROOT" ]
                |> List.reverse
                |> List.indexedMap
                    (\idx segment ->
                        if idx == 0 && amountOfSegments == 0 then
                            Just <| rootPathPart model segments

                        else if idx == 0 then
                            Just <| activePathPart (amountOfSegments - idx + 1) segment

                        else if idx == 1 then
                            Just <| inactivePathPart (amountOfSegments - idx + 1) "…"

                        else
                            Nothing
                    )
                |> List.filterMap identity
                |> List.reverse
                |> List.intersperse pathSeparator
                |> Html.div
                    [ T.flex_auto
                    , T.italic
                    , T.leading_snug
                    , T.text_2xl
                    , T.tracking_tight

                    --
                    , T.md__hidden
                    ]

            -----------------------------------------
            -- Actions
            -----------------------------------------
            -- , Html.div
            --     [ T.border_2
            --     , T.border_gray_500
            --     , T.cursor_not_allowed
            --     , T.pl_8
            --     , T.pr_3
            --     , T.py_1
            --     , T.relative
            --     , T.rounded_full
            --     , T.text_gray_500
            --     , T.w_48
            --
            --     -- Dark mode
            --     ------------
            --     , T.dark__border_gray_200
            --     , T.dark__text_gray_200
            --     ]
            --     [ FeatherIcons.search
            --         |> FeatherIcons.withSize 20
            --         |> FeatherIcons.toHtml []
            --         |> List.singleton
            --         |> Html.span
            --             [ T.absolute
            --             , T.left_0
            --             , T.ml_2
            --             , T.neg_translate_y_1over2
            --             , T.text_gray_500
            --             , T.top_1over2
            --             , T.transform
            --
            --             -- Dark mode
            --             ------------
            --             , T.dark__text_gray_200
            --             ]
            --
            --     --
            --     , Html.text "Search"
            --     ]
            --
            , Html.div
                [ T.flex
                , T.items_center
                , T.ml_12
                ]
                [ FeatherIcons.menu
                    |> FeatherIcons.withSize S.iconSize
                    |> FeatherIcons.toHtml []
                    |> List.singleton
                    |> Html.span [ T.pointer_events_none ]
                    |> List.singleton
                    |> Html.span
                        [ { authenticated = Maybe.isJust model.authenticated }
                            |> ContextMenu.hamburger
                            |> ShowContextMenu
                            |> M.onClick

                        --
                        , T.cursor_pointer
                        , T.text_gray_300
                        ]
                ]
            ]
        ]


inactivePathPart : Int -> String -> Html Msg
inactivePathPart floor text =
    let
        isPublicRootDir =
            floor == 2 && text == "public"
    in
    Html.span
        [ A.class "underline-thick"

        --
        , { floor = floor }
            |> GoUp
            |> E.onClick

        --
        , T.cursor_pointer
        , T.pb_px
        , T.tdc_gray_500
        , T.text_gray_300
        , T.underline

        -- Dark mode
        ------------
        , T.dark__tdc_gray_200
        , T.dark__text_gray_400
        ]
        [ if isPublicRootDir then
            Html.map never publicDirPart

          else
            Html.text text
        ]


activePathPart : Int -> String -> Html Msg
activePathPart floor text =
    let
        isPublicRootDir =
            floor == 2 && text == "public"
    in
    Html.span
        [ T.text_purple ]
        [ if isPublicRootDir then
            Html.map never publicDirPart

          else
            Html.text text
        ]


pathSeparator : Html Msg
pathSeparator =
    Html.span
        [ T.antialiased
        , T.mx_3
        , T.text_gray_500

        -- Dark mode
        ------------
        , T.dark__text_gray_200
        ]
        [ Html.text "/" ]


rootPathPart : Model -> List String -> Html Msg
rootPathPart model segments =
    let
        root =
            model.foundation
                |> Maybe.map .unresolved
                |> Maybe.withDefault ""

        rootLength =
            String.length root

        isDnsLink =
            Maybe.unwrap False .isDnsLink model.foundation

        isTooLong =
            (isDnsLink && rootLength > 36) || not isDnsLink

        text =
            if isTooLong then
                String.dropLeft (rootLength - 12) root

            else
                root

        attributes =
            case segments of
                [] ->
                    [ T.pb_px
                    , T.text_purple
                    ]

                _ ->
                    [ A.class "underline-thick"

                    --
                    , { floor = 0 }
                        |> GoUp
                        |> E.onClick

                    --
                    , T.cursor_pointer
                    , T.pb_px
                    , T.tdc_gray_500
                    , T.text_gray_300
                    , T.underline

                    -- Dark mode
                    ------------
                    , T.dark__tdc_gray_200
                    , T.dark__text_gray_400
                    ]
    in
    Html.span
        (if isTooLong then
            Common.fadeOutLeft :: attributes

         else
            attributes
        )
        [ Html.text text ]


publicDirPart : Html Never
publicDirPart =
    FeatherIcons.globe
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div [ A.style "vertical-align" "sub", T.inline_block ]



-- MAIN


content : Model -> Html Msg
content model =
    case model.directoryList of
        Ok directoryList ->
            case directoryList.items of
                [] ->
                    empty

                _ ->
                    contentAvailable model directoryList

        Err err ->
            Html.div
                [ T.flex
                , T.flex_1
                , T.items_center
                , T.justify_center
                , T.p_5
                ]
                [ Html.div
                    [ T.max_w_md ]
                    [ Html.text err ]
                ]


empty : Html Msg
empty =
    Html.div
        [ T.flex
        , T.flex_auto
        , T.flex_col
        , T.items_center
        , T.justify_center
        , T.leading_snug
        , T.text_center
        , T.text_gray_300

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ FeatherIcons.folder
            |> FeatherIcons.withSize 88
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> Html.div [ T.opacity_30 ]

        --
        , Html.div
            [ T.mt_4, T.text_lg ]
            [ Html.text "Nothing to see here,"
            , Html.br [] []
            , Html.text "empty directory"
            ]
        ]


contentAvailable : Model -> { floor : Int, items : List Item } -> Html Msg
contentAvailable model directoryList =
    Html.div
        [ T.flex
        , T.flex_auto
        , T.relative
        , T.z_0
        ]
        [ Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.flex_auto
            , T.items_stretch
            , T.mx_auto
            , T.my_8
            ]
            [ -----------------------------------------
              -- Left
              -----------------------------------------
              Html.div
                (List.append
                    [ A.id "drive-items"

                    --
                    , T.flex_auto
                    , T.w_1over2
                    ]
                    (let
                        hideContent =
                            Maybe.isJust model.selectedPath
                                || (model.sidebarMode /= Sidebar.defaultMode)
                     in
                     if model.expandSidebar then
                        [ T.hidden ]

                     else if hideContent then
                        [ T.hidden, T.md__block, T.pr_12, T.lg__pr_24 ]

                     else
                        [ T.pr_12, T.lg__pr_24 ]
                    )
                )
                [ list model directoryList
                ]

            -----------------------------------------
            -- Right
            -----------------------------------------
            , Sidebar.view model
            ]
        ]



-- MAIN  /  LIST


list : Model -> { floor : Int, items : List Item } -> Html Msg
list model directoryList =
    let
        isGroundFloor =
            directoryList.floor == 1
    in
    Html.div
        [ T.text_lg ]
        [ Html.div
            [ T.antialiased
            , T.font_semibold
            , T.mb_1
            , T.text_gray_400
            , T.text_xs
            , T.tracking_wider

            -- Dark mode
            ------------
            , T.dark__text_gray_300
            ]
            [ Html.text "NAME" ]

        -----------------------------------------
        -- Tree
        -----------------------------------------
        , directoryList.items
            |> List.map (listItem isGroundFloor model.selectedPath)
            |> Html.div []

        -----------------------------------------
        -- Stats
        -----------------------------------------
        , let
            ( amountOfDirs, amountOfFiles, size ) =
                List.foldl
                    (\i ( d, f, s ) ->
                        if i.kind == Directory then
                            ( d + 1, f, s + i.size )

                        else
                            ( d, f + 1, s + i.size )
                    )
                    ( 0, 0, 0 )
                    directoryList.items

            sizeString =
                Common.sizeInWords size
          in
          Html.div
            [ T.mt_8
            , T.text_gray_400
            , T.text_sm

            -- Dark mode
            ------------
            , T.dark__text_gray_300
            ]
            [ case amountOfDirs of
                0 ->
                    nothing

                1 ->
                    Html.text (String.fromInt amountOfDirs ++ " Directory")

                _ ->
                    Html.text (String.fromInt amountOfDirs ++ " Directories")

            --
            , Html.viewIf
                (amountOfDirs > 0 && amountOfFiles > 0)
                (Html.text " and ")

            --
            , case amountOfFiles of
                0 ->
                    nothing

                1 ->
                    Html.text (String.fromInt amountOfFiles ++ " File (" ++ sizeString ++ ")")

                _ ->
                    Html.text (String.fromInt amountOfFiles ++ " Files (" ++ sizeString ++ ")")
            ]
        ]


listItem : Bool -> Maybe String -> Item -> Html Msg
listItem isGroundFloor selectedPath ({ kind, loading, name, nameProperties, path } as item) =
    let
        selected =
            selectedPath == Just path

        isPublicRootDir =
            isGroundFloor && name == "public"
    in
    Html.div
        [ case kind of
            Directory ->
                { directoryName = name }
                    |> DigDeeper
                    |> E.onClick

            _ ->
                item
                    |> Select
                    |> E.onClick

        --
        , T.border_gray_700
        , T.cursor_pointer
        , T.flex
        , T.group
        , T.items_center
        , T.mt_px
        , T.py_4

        --
        , if isPublicRootDir then
            T.border_b_2

          else
            T.border_b

        --
        , if selected then
            T.text_purple

          else
            T.text_inherit

        -- Dark mode
        ------------
        , T.dark__border_darkness_above

        --
        , if selected then
            T.dark__text_white

          else
            T.dark__text_inherit
        ]
        [ -----------------------------------------
          -- Icon
          -----------------------------------------
          (if isPublicRootDir then
            FeatherIcons.globe

           else
            Drive.Item.kindIcon kind
          )
            |> FeatherIcons.withSize S.iconSize
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> Html.div [ T.flex_shrink_0 ]

        -----------------------------------------
        -- Label
        -----------------------------------------
        , Html.span
            [ T.flex_auto, T.ml_5, T.truncate ]
            [ if isPublicRootDir then
                Html.text "Public"

              else
                Html.text nameProperties.base

            --
            , case nameProperties.extension of
                "" ->
                    nothing

                ext ->
                    Html.span
                        [ T.antialiased
                        , T.bg_gray_600
                        , S.default_transition_duration
                        , T.font_semibold
                        , T.inline_block
                        , T.leading_normal
                        , T.ml_2
                        , T.opacity_0
                        , T.pointer_events_none
                        , T.px_1
                        , T.rounded
                        , T.text_gray_200
                        , T.text_xs
                        , T.transition_opacity
                        , T.uppercase

                        -- Dark mode
                        ------------
                        , T.dark__bg_gray_200
                        , T.dark__text_gray_500

                        -- Group
                        --------
                        , T.group_hover__opacity_100
                        , T.group_hover__pointer_events_auto
                        ]
                        [ Html.text ext ]
            ]

        -----------------------------------------
        -- Tail
        -----------------------------------------
        , if loading then
            FeatherIcons.loader
                |> FeatherIcons.withSize S.iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span
                    [ T.animation_spin
                    , T.ml_2
                    , T.text_gray_300
                    ]

          else
            nothing

        --
        , if selected then
            FeatherIcons.arrowRight
                |> FeatherIcons.withSize S.iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span [ T.ml_2, T.opacity_50 ]

          else
            nothing
        ]
