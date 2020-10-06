module Drive.View exposing (view)

import Common exposing (ifThenElse)
import Common.View as Common
import Common.View.Footer as Footer
import ContextMenu
import Drive.ContextMenu as ContextMenu
import Drive.Item exposing (Item, Kind(..))
import Drive.Sidebar as Sidebar
import Drive.View.Sidebar as Sidebar
import FeatherIcons
import FileSystem
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Ext as E
import Html.Events.Extra.Mouse as M
import Html.Events.Extra.Touch as T
import Html.Extra as Html exposing (nothing)
import Json.Decode as Decode
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
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
        , primary model

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
                |> Common.wrapIcon
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
                    (a / b) > 21.5
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
                    |> Common.wrapIcon [ T.pointer_events_none ]
                    |> List.singleton
                    |> Html.span
                        [ model
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
        [ namePart floor text ]


activePathPart : Int -> String -> Html Msg
activePathPart floor text =
    Html.span
        [ T.text_purple ]
        [ namePart floor text ]


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
            case Routing.treeRoot model.route of
                Just r ->
                    r

                Nothing ->
                    ""

        rootLength =
            String.length root

        isTooLong =
            rootLength > 36

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


namePart : Int -> String -> Html Msg
namePart floor text =
    let
        isPublicRootDir =
            floor == 2 && text == "public"
    in
    if isPublicRootDir then
        Html.map never publicDirPart

    else
        case Drive.Item.nameIconForBasename text of
            Just icon ->
                breadcrumbIcon icon

            Nothing ->
                Html.text text


publicDirPart : Html Never
publicDirPart =
    breadcrumbIcon FeatherIcons.globe


breadcrumbIcon : FeatherIcons.Icon -> Html msg
breadcrumbIcon icon =
    icon
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div [ A.style "vertical-align" "sub", T.inline_block ]



-- MAIN


primary : Model -> Html Msg
primary model =
    case ( model.fileSystemStatus, model.directoryList ) of
        ( FileSystem.Error err, _ ) ->
            errorView model.route err

        ( _, Err err ) ->
            errorView model.route err

        ( _, Ok directoryList ) ->
            mainLayout
                model
                (case directoryList.items of
                    [] ->
                        if model.expandSidebar then
                            Html.nothing

                        else
                            empty model

                    _ ->
                        contentAvailable model directoryList
                )


mainLayout : Model -> Html Msg -> Html Msg
mainLayout model leftSide =
    Html.div
        [ T.flex
        , T.flex_col
        , T.flex_auto
        , T.relative
        , T.z_0
        ]
        [ -----------------------------------------
          -- Welcome message
          -----------------------------------------
          case Maybe.map .newUser model.authenticated of
            Just True ->
                Html.div
                    [ T.container
                    , T.flex
                    , T.justify_start
                    , T.mt_8
                    , T.mx_auto
                    , T.w_full
                    ]
                    [ Html.div
                        [ T.bg_gray_600
                        , T.leading_relaxed
                        , T.max_w_md
                        , T.ml_6
                        , T.p_6
                        , T.relative
                        , T.rounded_l_md
                        , T.text_gray_300
                        , T.text_sm

                        -- Dark mode
                        ------------
                        , T.dark__bg_darkness_above
                        , T.dark__text_gray_400
                        ]
                        [ Html.div
                            []
                            [ Html.strong
                                [ T.font_semibold ]
                                [ Html.text "Welcome to your Drive!" ]
                            , Html.text " Here you can browse through your entire filesystem. This filesystem holds all your public and private data, which you can take with you to "
                            , Html.a
                                [ A.href "https://fission.codes/apps"
                                , A.target "_blank"

                                --
                                , T.underline
                                , T.underline_thick
                                , T.tdc_pink_shade
                                ]
                                [ Html.text "various apps" ]
                            , Html.text ". If you want to make an app yourself, check out the "
                            , Html.a
                                [ A.href "https://guide.fission.codes/hosting/installation"
                                , A.target "_blank"

                                --
                                , T.underline
                                , T.underline_thick
                                , T.tdc_pink_shade
                                ]
                                [ Html.text "Fission CLI" ]
                            , Html.text "."
                            ]
                        ]

                    -------------------
                    -- Close button bar
                    -------------------
                    , Html.div
                        [ A.title "Hide"
                        , E.onClick HideWelcomeMessage

                        --
                        , T.bg_red
                        , T.bg_opacity_25
                        , T.cursor_pointer
                        , T.flex_shrink_0
                        , T.mr_6
                        , T.relative
                        , T.rounded_r_md
                        , T.text_pink_shade
                        , T.w_8
                        ]
                        [ Html.div
                            [ T.absolute
                            , T.flex
                            , T.items_center
                            , T.left_1over2
                            , T.neg_translate_x_1over2
                            , T.neg_translate_y_1over2
                            , T.rotate_90
                            , T.transform
                            , T.top_1over2
                            ]
                            [ FeatherIcons.x
                                |> FeatherIcons.withSize 15
                                |> Common.wrapIcon [ T.mt_px ]
                            , Html.span
                                [ T.inline_block
                                , T.ml_1
                                , T.text_xs
                                , T.tracking_wider
                                ]
                                [ Html.text "CLOSE" ]
                            ]
                        ]

                    --
                    , Html.div
                        [ A.class "drive-bg-pattern"
                        , T.flex_auto
                        , T.opacity_40
                        , T.rounded_md

                        -- Dark mode
                        ------------
                        , T.dark__opacity_20
                        ]
                        []
                    ]

            _ ->
                Html.nothing

        -----------------------------------------
        -- Default content
        -----------------------------------------
        , Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.flex_auto
            , T.items_stretch
            , T.mx_auto
            , T.my_8
            , T.w_full
            ]
            [ -- Left
              -------
              leftSide

            -- Right
            --------
            , Sidebar.view model
            ]
        ]


errorView : Routing.Route -> String -> Html Msg
errorView route err =
    Html.div
        [ T.flex_auto
        , T.flex_col
        , T.items_center
        , T.justify_center
        , T.leading_snug
        , T.text_center
        , T.text_gray_300

        --
        , T.md__flex

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ FeatherIcons.zapOff
            |> FeatherIcons.withSize 88
            |> Common.wrapIcon [ T.opacity_30 ]

        --
        , Html.div
            [ T.max_w_md
            , T.mt_5
            , T.text_lg
            ]
            [ case err of
                "file does not exist" ->
                    Html.text "Couldn't find this item"

                "Path does not exist" ->
                    Html.text "Couldn't find this item"

                _ ->
                    Html.text err
            ]

        --
        , S.buttonLink
            [ if String.contains "filesystem" err then
                A.href "#/"

              else
                []
                    |> Routing.replaceTreePathSegments route
                    |> Routing.routeFragment
                    |> Maybe.withDefault "/"
                    |> String.append "#"
                    |> A.href

            --
            , T.bg_purple
            , T.mt_5
            , T.text_tiny
            ]
            [ Html.text "Get me out of here"
            ]
        ]


empty : Model -> Html Msg
empty model =
    let
        isAuthenticated =
            Maybe.isJust model.authenticated

        hideContent =
            model.sidebarMode /= Sidebar.defaultMode
    in
    Html.div
        [ if isAuthenticated then
            E.onClick (ToggleSidebarMode Sidebar.AddOrCreate)

          else
            E.onClick Bypass

        --
        , ifThenElse hideContent T.hidden T.flex
        , ifThenElse isAuthenticated T.cursor_pointer T.cursor_default

        --
        , T.flex_auto
        , T.flex_col
        , T.items_center
        , T.justify_center
        , T.leading_snug
        , T.text_center
        , T.text_gray_300

        --
        , T.md__flex

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]
        [ if isAuthenticated then
            FeatherIcons.plus
                |> FeatherIcons.withSize 88
                |> Common.wrapIcon [ T.opacity_30 ]

          else
            FeatherIcons.folder
                |> FeatherIcons.withSize 88
                |> Common.wrapIcon [ T.opacity_30 ]

        --
        , Html.div
            [ T.mt_4
            , T.text_lg
            ]
            (case model.authenticated of
                Just _ ->
                    [ Html.text "Nothing here yet,"
                    , Html.br [] []
                    , Html.text "click or drag to add"
                    ]

                Nothing ->
                    [ Html.text "Nothing to see here,"
                    , Html.br [] []
                    , Html.text "empty directory"
                    ]
            )
        ]


contentAvailable : Model -> { floor : Int, items : List Item } -> Html Msg
contentAvailable model directoryList =
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
        { base } =
            nameProperties

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
                    |> E.onTap

            _ ->
                item
                    |> Select
                    |> E.onTap

        -- Show context menu on right click,
        -- or when holding, without moving, the item on touch devices.
        , item
            |> ContextMenu.item
                ContextMenu.TopCenterWithoutOffset
                { isGroundFloor = isGroundFloor }
            |> ShowContextMenu
            |> M.onContextMenu

        --
        , E.custom
            "longtap"
            (Decode.map2
                (\x y ->
                    { message =
                        item
                            |> ContextMenu.item
                                ContextMenu.TopCenterWithoutOffset
                                { isGroundFloor = isGroundFloor }
                            |> ShowContextMenuWithCoordinates { x = x, y = y }

                    --
                    , stopPropagation = True
                    , preventDefault = False
                    }
                )
                (Decode.field "x" Decode.float)
                (Decode.field "y" Decode.float)
            )

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
            item
                |> Drive.Item.nameIcon
                |> Maybe.withDefault (Drive.Item.kindIcon kind)
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
            Common.loadingAnimationWithAttributes
                [ T.ml_2
                , T.text_gray_300
                ]
                { size = S.iconSize }

          else
            nothing

        --
        , if selected then
            FeatherIcons.arrowRight
                |> FeatherIcons.withSize S.iconSize
                |> Common.wrapIcon [ T.ml_2, T.opacity_50 ]

          else
            nothing
        ]
