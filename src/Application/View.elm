module View exposing (view)

import Browser
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ipfs
import Item exposing (Item, Kind(..))
import List.Extra as List
import Routing exposing (Page(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
import Url.Builder



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body =
        body model

    -- TODO: IPNS/...
    }


body : Model -> List (Html Msg)
body m =
    if m.ipfs == Ipfs.Connecting || m.directoryList == Nothing then
        [ Html.img
            [ A.src "images/loader.svg"

            --
            , T.absolute
            , T.animation_spin
            , T.left_1over2
            , T.neg_translate_y_1over2
            , T.top_1over2
            ]
            []
        ]

    else
        [ header m
        , content m
        , footer m
        ]
            |> Html.div
                [ T.flex
                , T.flex_col
                , T.min_h_screen
                ]
            |> List.singleton



-- HEADER


header : Model -> Html Msg
header model =
    Html.header
        [ T.bg_gray_200
        , T.py_8
        , T.text_white
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
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.div
                    [ T.mr_5
                    , T.opacity_50
                    , T.text_pink
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
                    [ case segments of
                        [] ->
                            activePathPart "My Drive"

                        _ ->
                            inactivePathPart 0 "My Drive"
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
                , T.text_gray_400

                --
                , T.lg__flex
                ]
                [ Html.div
                    [ T.border_2
                    , T.border_gray_300
                    , T.cursor_not_allowed
                    , T.pl_8
                    , T.pr_3
                    , T.py_1
                    , T.relative
                    , T.rounded_full
                    , T.text_gray_300
                    , T.w_48
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
                            , T.text_gray_300
                            , T.top_1over2
                            , T.transform
                            ]

                    --
                    , Html.text "Search"
                    ]
                ]
            ]
        ]


inactivePathPart idx text =
    Html.span
        [ A.class "underline-thick"
        , E.onClick (GoUp { floor = idx })

        --
        , T.cursor_pointer
        , T.pb_px
        , T.tdc_gray_300
        , T.text_gray_500
        , T.underline
        ]
        [ Html.text text ]


activePathPart text =
    Html.span
        [ T.text_pink ]
        [ Html.text text ]


pathSeparator =
    Html.span [ T.antialiased, T.mx_3, T.text_gray_300 ] [ Html.text "/" ]



-- MAIN


content m =
    Html.div
        [ T.container
        , S.container_padding
        , T.flex
        , T.flex_auto
        , T.items_stretch
        , T.mx_auto
        , T.my_8
        ]
        [ list m

        -- TODO
        -- , details m
        ]



-- MAIN  /  LIST


list : Model -> Html Msg
list model =
    Html.div
        [ T.flex_auto
        , T.text_lg
        , T.w_1over2
        ]
        [ Html.div
            [ T.antialiased
            , T.font_semibold
            , T.mb_1
            , T.text_gray_400
            , T.text_xs
            , T.tracking_wider
            ]
            [ Html.text "NAME" ]

        -----------------------------------------
        -- Tree
        -----------------------------------------
        , model.directoryList
            |> Maybe.withDefault []
            |> List.sortWith
                (\a b ->
                    -- Put directories on top,
                    -- and then sort alphabetically by name
                    case ( a.kind, b.kind ) of
                        ( Directory, _ ) ->
                            LT

                        ( _, Directory ) ->
                            GT

                        ( _, _ ) ->
                            compare a.name b.name
                )
            |> List.map (listItem model)
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
                    (Maybe.withDefault [] model.directoryList)

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
            ]
            [ case amountOfDirs of
                0 ->
                    Html.text ""

                1 ->
                    Html.text (String.fromInt amountOfDirs ++ " Directory")

                _ ->
                    Html.text (String.fromInt amountOfDirs ++ " Directories")

            --
            , if amountOfDirs > 0 && amountOfFiles > 0 then
                Html.text " and "

              else
                Html.text ""

            --
            , case amountOfFiles of
                0 ->
                    Html.text ""

                1 ->
                    Html.text (String.fromInt amountOfFiles ++ " File (" ++ sizeString ++ ")")

                _ ->
                    Html.text (String.fromInt amountOfFiles ++ " Files (" ++ sizeString ++ ")")
            ]
        ]


listItem : Model -> Item -> Html Msg
listItem model { kind, loading, name, nameProperties, selected } =
    (case kind of
        Directory ->
            Html.div

        _ ->
            Html.a
    )
        [ case kind of
            Directory ->
                E.onClick (DigDeeper name)

            _ ->
                [ name ]
                    |> List.append (Routing.drivePathSegments model.page)
                    |> (::) model.rootCid
                    |> String.join "/"
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
            T.text_pink

          else
            T.text_inherit
        ]
        [ -----------------------------------------
          -- Icon
          -----------------------------------------
          kind
            |> Item.kindIcon
            |> FeatherIcons.withSize iconSize
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
                    Html.text ""

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
                        ]
                        [ Html.text ext ]
            ]

        --
        , if loading then
            FeatherIcons.loader
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span [ T.animation_spin, T.ml_2 ]

          else
            Html.text ""

        --
        , if selected then
            FeatherIcons.arrowRight
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span [ T.ml_2, T.opacity_50 ]

          else
            Html.text ""
        ]



-- MAIN  /  DETAILS


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



-- FOOTER


footer _ =
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
            [ footerLeft
            , Html.div [ T.flex_auto ] []
            , footerRight
            ]
        ]


footerLeft =
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


footerRight =
    Html.div
        [ T.flex
        , T.items_center
        , T.text_gray_300
        ]
        [ htmlWithIcon
            FeatherIcons.helpCircle
            [ Html.text "Help" ]
        ]



-- 🛠


htmlWithIcon : FeatherIcons.Icon -> List (Html Msg) -> Html Msg
htmlWithIcon icon nodes =
    Html.span
        [ T.cursor_pointer
        , T.inline_flex
        , T.items_center
        ]
        [ icon
            |> FeatherIcons.withSize iconSize
            |> FeatherIcons.toHtml []

        --
        , Html.span
            [ T.ml_2 ]
            nodes
        ]


iconSize =
    22
