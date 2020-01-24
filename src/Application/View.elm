module View exposing (view)

import Browser
import Html exposing (Html)
import Html.Attributes as A
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
        [ T.border_b
        , T.border_gray_600
        , T.container
        , T.mx_auto
        , T.py_8
        ]
        [ -----------------------------------------
          -- Path
          -----------------------------------------
          Html.div
            [ T.text_2xl
            , T.tracking_tight
            ]
            [ inactivePathPart "Name of Root Directory"
            , Html.span [ T.mx_4, T.text_gray_400 ] [ Html.text "/" ]
            , Html.text "Photos"
            ]
        ]


inactivePathPart text =
    Html.span
        [ A.style "text-decoration-thickness" "2px"

        --
        , T.pb_px
        , T.tdc_gray_500
        , T.text_gray_300
        , T.underline
        ]
        [ Html.text text ]



-- LIST


list _ =
    Html.div
        [ T.flex_1 ]
        [ Html.text "" ]



-- FOOTer


footer _ =
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
        |> Html.div
            [ T.container
            , T.flex
            , T.items_center
            , T.mx_auto
            , T.mt_px
            , T.py_8
            ]
        |> List.singleton
        |> Html.footer
            [ T.bg_gray_600
            , T.pt_px
            ]
