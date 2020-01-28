module View exposing (view)

import Browser
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Item exposing (Kind(..))
import List.Extra as List
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body = body model
    }


body : Model -> List (Html Msg)
body m =
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


header _ =
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
                |> Html.div [ T.mr_5, T.text_gray_300 ]

            -----------------------------------------
            -- Path
            -----------------------------------------
            , Html.div
                [ T.flex_auto
                , T.italic
                , T.text_2xl
                , T.tracking_tight
                ]
                [ inactivePathPart "My Drive"
                , pathSeparator
                , activePathPart "Music"
                ]

            -----------------------------------------
            -- Actions
            -----------------------------------------
            , Html.div
                [ T.flex
                , T.items_center
                , T.ml_4
                , T.text_gray_400
                ]
                [ Html.div
                    [ T.border_2
                    , T.border_gray_300
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


inactivePathPart text =
    Html.span
        [ A.class "underline-thick"

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
        , details m
        ]



-- MAIN  /  LIST


staticList =
    [ { kind = Directory
      , name = "Drum n' Bass"
      , active = False
      }
    , { kind = Directory
      , name = "Metal"
      , active = False
      }
    , { kind = Directory
      , name = "Techno & Minimal"
      , active = True
      }
    , { kind = Directory
      , name = "Trip Hop & Lo-Fi"
      , active = False
      }

    --
    , { kind = Audio
      , name = "Aretha Franklin - Save Me.m4a"
      , active = False
      }
    , { kind = Audio
      , name = "IAMNOBODI - Mad World.mp3"
      , active = False
      }
    ]


list _ =
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
        , Html.div
            []
            (List.indexedMap
                listItem
                staticList
            )

        -----------------------------------------
        -- Stats
        -----------------------------------------
        , Html.div
            [ T.mt_8
            , T.text_gray_400
            , T.text_sm
            ]
            [ Html.text "4 Directories and 2 files, 80MB" ]
        ]


listItem idx { kind, name, active } =
    let
        withoutDots =
            String.split "." name

        ( extension, label ) =
            if List.length withoutDots > 1 then
                withoutDots
                    |> List.unconsLast
                    |> Maybe.map (Tuple.mapSecond <| String.join ".")
                    |> Maybe.withDefault ( "", name )

            else
                ( "", name )
    in
    Html.div
        [ T.border_b
        , T.border_gray_700
        , T.flex
        , T.items_center
        , T.mt_px
        , T.py_4

        --
        , if active then
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
            [ Html.text label

            --
            , case extension of
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
        , if active then
            FeatherIcons.arrowRight
                |> FeatherIcons.withSize iconSize
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.span [ T.opacity_50 ]

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
