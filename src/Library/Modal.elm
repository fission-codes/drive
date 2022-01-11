module Modal exposing (..)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Events as E
import Tailwind as T



-- 🧩


type alias Modal msg =
    { confirmationButtons : Dict String String -> List (Html msg)
    , content : Dict String String -> List (Html msg)
    , onSubmit : msg
    , state : Dict String String
    , title : String
    }



-- 🖼


view : Modal msg -> Html msg
view modal =
    Html.section
        [ T.bg_base_50
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
        , T.dark__bg_base_800
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
        , Html.form
            [ E.onSubmit modal.onSubmit ]
            [ Html.div
                []
                (modal.content modal.state)

            -- Confirmation Buttons
            -----------------------
            , Html.div
                [ T.flex
                , T.items_center
                , T.justify_center
                , T.mt_5
                , T.space_x_3
                ]
                (modal.confirmationButtons modal.state)
            ]
        ]
