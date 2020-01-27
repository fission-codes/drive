module View exposing (view)

import Browser
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Item exposing (Kind(..))
import List.Extra as List
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
    , list m
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
        [ T.bg_gray_100
        , T.bg_gradient_b_gray_100_200
        , T.py_8
        , T.text_white
        ]
        [ Html.div
            [ T.container
            , T.flex
            , T.items_center
            , T.mx_auto
            , T.pb_px
            ]
            [ -----------------------------------------
              -- Icon
              -----------------------------------------
              FeatherIcons.hardDrive
                |> FeatherIcons.withSize 23
                |> FeatherIcons.toHtml []
                |> List.singleton
                |> Html.div [ T.mr_5, T.text_gray_200 ]

            -----------------------------------------
            -- Path
            -----------------------------------------
            , Html.div
                [ T.flex_auto
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
                , T.text_gray_400
                ]
                [ FeatherIcons.anchor
                    |> FeatherIcons.withSize 23
                    |> FeatherIcons.toHtml []
                    |> List.singleton
                    |> Html.div
                        [ T.cursor_pointer
                        , T.ml_3
                        , T.text_gray_300
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
        , T.tdc_gray_200
        , T.text_gray_500
        , T.underline
        ]
        [ Html.text text ]


activePathPart =
    Html.text


pathSeparator =
    Html.span [ T.antialiased, T.mx_3, T.text_gray_200 ] [ Html.text "/" ]



-- LIST


staticList =
    [ { kind = Directory
      , name = "Drum n' Bass"
      }
    , { kind = Directory
      , name = "Metal"
      }
    , { kind = Directory
      , name = "Techno & Minimal"
      }
    , { kind = Directory
      , name = "Trip Hop & Lo-Fi"
      }

    --
    , { kind = Audio
      , name = "Aretha Franklin - Save Me.m4a"
      }
    , { kind = Audio
      , name = "IAMNOBODI - Mad World.mp3"
      }
    ]


list _ =
    Html.div
        [ T.container
        , T.flex_1
        , T.mx_auto
        , T.my_6
        , T.text_lg
        ]
        [ Html.div
            [ T.w_1over2 ]
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


listItem idx { kind, name } =
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
        , T.border_near_white
        , T.flex
        , T.items_center
        , T.py_4
        ]
        [ -----------------------------------------
          -- Icon
          -----------------------------------------
          kind
            |> Item.kindIcon
            |> FeatherIcons.withSize 23
            |> FeatherIcons.toHtml []
            |> List.singleton
            |> Html.span [ T.text_gray_300 ]

        -----------------------------------------
        -- Label & Extensions
        -----------------------------------------
        , Html.span
            [ T.ml_5 ]
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
        ]



-- FOOTER


footer _ =
    Html.footer
        [ T.bg_gray_600
        , T.pt_px
        ]
        [ Html.div
            [ T.container
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
            |> FeatherIcons.withSize 23
            |> FeatherIcons.toHtml []

        --
        , Html.span
            [ T.ml_2 ]
            nodes
        ]
