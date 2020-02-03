module Drive.View exposing (view)

import Explore.View as Explore
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html exposing (nothing)
import Ipfs
import Item exposing (Item, Kind(..))
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation.Types as Navigation
import Routing exposing (Page(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
import Url.Builder
import View.Common
import View.Common.Footer as Footer



-- 🖼


view : Model -> Html Msg
view model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.h_screen
        ]
        [ header model
        , content model
        , Footer.view model
        ]



-- HEADER


header : Model -> Html Msg
header model =
    Html.header
        [ T.bg_gray_600
        , T.py_8
        , T.text_white

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
            , T.pb_1
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
            , let
                segments =
                    Routing.drivePathSegments model.page

                amountOfSegments =
                    List.length segments
              in
              segments
                |> List.reverse
                |> List.indexedMap
                    (\idx ->
                        if idx == 0 then
                            activePathPart

                        else
                            inactivePathPart (amountOfSegments - idx + 1)
                    )
                |> List.reverse
                |> List.append
                    [ rootPathPart model segments
                    ]
                |> List.intersperse pathSeparator
                |> Html.div
                    [ T.flex_auto
                    , T.italic
                    , T.leading_snug
                    , T.text_2xl
                    , T.tracking_tight
                    ]

            -----------------------------------------
            -- Actions
            -----------------------------------------
            , Html.div
                [ T.hidden
                , T.items_center
                , T.ml_4

                --
                , T.lg__flex
                ]
                [ Html.div
                    [ T.border_2
                    , T.border_gray_500
                    , T.cursor_not_allowed
                    , T.pl_8
                    , T.pr_3
                    , T.py_1
                    , T.relative
                    , T.rounded_full
                    , T.text_gray_500
                    , T.w_48

                    -- Dark mode
                    ------------
                    , T.dark__border_gray_200
                    , T.dark__text_gray_200
                    ]
                    [ FeatherIcons.search
                        |> FeatherIcons.withSize 20
                        |> FeatherIcons.toHtml []
                        |> List.singleton
                        |> Html.span
                            [ T.absolute
                            , T.left_0
                            , T.ml_2
                            , T.neg_translate_y_1over2
                            , T.text_gray_500
                            , T.top_1over2
                            , T.transform

                            -- Dark mode
                            ------------
                            , T.dark__text_gray_200
                            ]

                    --
                    , Html.text "Search"
                    ]
                ]
            ]
        ]


inactivePathPart : Int -> String -> Html Msg
inactivePathPart idx text =
    Html.span
        [ A.class "underline-thick"

        --
        , { floor = idx }
            |> Navigation.GoUp
            |> NavigationMsg
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
        [ Html.text text ]


activePathPart : String -> Html Msg
activePathPart text =
    Html.span
        [ T.text_purple ]
        [ Html.text text ]


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
        rootCid =
            Maybe.withDefault "" model.rootCid

        text =
            String.dropLeft (String.length rootCid - 12) rootCid

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
                        |> Navigation.GoUp
                        |> NavigationMsg
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
        (View.Common.fadeOutLeft :: attributes)
        [ Html.text text ]



-- MAIN


content : Model -> Html Msg
content model =
    case model.directoryList of
        Ok [] ->
            empty

        Ok directoryList ->
            contentAvailable model directoryList

        Err err ->
            -- Error is handled by the root view,
            -- which will render the explore view.
            empty


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
        ]
        [ FeatherIcons.folder
            |> FeatherIcons.withSize 88
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> Html.div [ T.opacity_50 ]

        --
        , Html.div
            [ T.mt_4, T.text_lg ]
            [ Html.text "Nothing to see here,"
            , Html.br [] []
            , Html.text "empty directory"
            ]
        ]


contentAvailable : Model -> List Item -> Html Msg
contentAvailable model directoryList =
    Html.div
        [ T.flex
        , T.flex_auto
        , T.overflow_hidden
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
            [ Html.div
                [ T.flex_auto
                , T.overflow_x_hidden
                , T.overflow_y_scroll
                , T.w_1over2
                ]
                [ list model directoryList
                ]

            -- TODO:
            -- , details m
            ]
        ]



-- MAIN  /  LIST


list : Model -> List Item -> Html Msg
list model directoryList =
    let
        parentPath =
            model.page
                |> Routing.drivePathSegments
                |> (case model.rootCid of
                        Just rootCid ->
                            (::) rootCid

                        Nothing ->
                            identity
                   )
                |> String.join "/"
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
        , directoryList
            |> List.sortWith sortingFunction
            |> List.map (listItem parentPath)
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
                    directoryList

            sizeString =
                if toFloat size / 1000000 > 2 then
                    String.fromInt (size // 1000000) ++ "MB"

                else
                    String.fromInt (size // 1000) ++ "KB"
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


listItem : String -> Item -> Html Msg
listItem parentPath { kind, loading, name, nameProperties, selected } =
    (case kind of
        Directory ->
            Html.div

        _ ->
            Html.a
    )
        [ case kind of
            Directory ->
                name
                    |> Navigation.DigDeeper
                    |> NavigationMsg
                    |> E.onClick

            _ ->
                name
                    |> String.append "/"
                    |> String.append parentPath
                    |> String.append "https://ipfs.runfission.com/ipfs/"
                    |> A.href

        --
        , T.border_b
        , T.border_gray_700
        , T.cursor_pointer
        , T.flex
        , T.items_center
        , T.mt_px
        , T.py_4

        --
        , if selected then
            T.text_purple

          else
            T.text_inherit

        -- Dark mode
        ------------
        , T.dark__border_touch_of_darkness
        ]
        [ -----------------------------------------
          -- Icon
          -----------------------------------------
          kind
            |> Item.kindIcon
            |> FeatherIcons.withSize S.iconSize
            |> FeatherIcons.toHtml []

        -----------------------------------------
        -- Label & Extensions
        -----------------------------------------
        , Html.span
            [ T.flex_auto, T.ml_5 ]
            [ Html.text nameProperties.base

            --
            , case nameProperties.extension of
                "" ->
                    nothing

                ext ->
                    Html.span
                        [ T.antialiased
                        , T.bg_gray_600
                        , T.font_semibold
                        , T.leading_loose
                        , T.ml_2
                        , T.px_1
                        , T.py_px
                        , T.rounded
                        , T.text_gray_200
                        , T.text_xs
                        , T.uppercase

                        -- Dark mode
                        ------------
                        , T.dark__bg_gray_200
                        , T.dark__text_gray_500
                        ]
                        [ Html.text ext ]
            ]

        --
        , if loading then
            FeatherIcons.loader
                |> FeatherIcons.withSize S.iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span [ T.animation_spin, T.ml_2 ]

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



-- MAIN  /  DETAILS


details : Model -> Html Msg
details _ =
    Html.div
        [ T.bg_gray_900
        , T.flex
        , T.flex_auto
        , T.flex_col
        , T.items_center
        , T.justify_center
        , T.ml_12
        , T.px_4
        , T.py_6
        , T.rounded_md
        , T.w_1over2

        --
        , T.lg__ml_24
        ]
        [ FeatherIcons.folder
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
            ]
            [ Html.text "Techno & Minimal" ]

        --
        , Html.div
            [ T.mt_px
            , T.text_center
            , T.text_gray_300
            , T.text_sm
            ]
            [ Html.text "5 items, modified yesterday" ]

        --
        , Html.div
            [ T.mt_5
            ]
            [ Html.div
                [ T.antialiased
                , T.bg_purple
                , T.font_semibold
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
                    [ Html.text "Open" ]
                ]
            ]
        ]



-- 🛠


sortingFunction : Item -> Item -> Order
sortingFunction a b =
    -- Put directories on top,
    -- and then sort alphabetically by name
    case ( a.kind, b.kind ) of
        ( Directory, Directory ) ->
            compare (String.toLower a.name) (String.toLower b.name)

        ( Directory, _ ) ->
            LT

        ( _, Directory ) ->
            GT

        ( _, _ ) ->
            compare (String.toLower a.name) (String.toLower b.name)
