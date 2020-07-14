module Modal exposing (..)

import Html exposing (Html)
import Tailwind as T



-- 🧩


type alias Modal msg =
    { confirmationButtons : List (Html msg)
    , content : List (Html msg)
    , title : String
    }



-- 🖼


view : Modal msg -> Html msg
view modal =
    Html.section
        [ T.bg_gray_900
        , T.fixed
        , T.left_1over2
        , T.neg_translate_x_1over2
        , T.neg_translate_y_1over2
        , T.px_8
        , T.py_6
        , T.rounded_md
        , T.top_1over2
        , T.transform
        , T.z_50

        -- Dark mode
        ------------
        , T.dark__bg_darkness_above
        ]
        [ -----------------------------------------
          -- Title
          -----------------------------------------
          Html.h1
            [ T.mb_5
            , T.text_center
            , T.text_xl
            ]
            [ Html.text modal.title
            ]

        -----------------------------------------
        -- Content
        -----------------------------------------
        , Html.section
            []
            modal.content

        -----------------------------------------
        -- Confirmation Buttons
        -----------------------------------------
        , Html.div
            [ T.flex
            , T.items_center
            , T.justify_center
            , T.mt_5
            ]
            modal.confirmationButtons
        ]
