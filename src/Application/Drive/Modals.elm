module Drive.Modals exposing (..)

import Html exposing (Html)
import Html.Attributes as A
import Modal exposing (Modal)
import Styling as S
import Tailwind as T
import Types exposing (Msg)



-- ⚗️


renameFile : Modal Msg
renameFile =
    { confirmationButtons =
        [ S.button
            [ T.bg_purple ]
            [ Html.text "Rename"
            ]

        --
        , S.button
            [ T.bg_gray_500
            , T.ml_4

            -- Dark mode
            ------------
            , T.dark__bg_gray_200
            ]
            [ Html.text "Cancel"
            ]
        ]
    , content =
        [ S.textField
            [ A.placeholder "File name"

            --
            , T.w_full
            ]
            []
        ]
    , title = "Rename file"
    }
