module Drive.Modals exposing (..)

import Dict
import Drive.Item as Item exposing (Item, Kind(..))
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Modal exposing (Modal)
import Styling as S
import Tailwind as T
import Radix exposing (Msg(..))



-- ⚗️


renameItem : Item -> Modal Msg
renameItem item =
    { confirmationButtons =
        [ S.button
            [ E.onClick (RenameItem item)

            --
            , T.bg_purple
            , T.text_tiny
            ]
            [ Html.text "Rename"
            ]

        --
        , S.button
            [ E.onClick HideModal

            --
            , T.bg_gray_500
            , T.ml_3
            , T.text_tiny

            -- Dark mode
            ------------
            , T.dark__bg_gray_200
            ]
            [ Html.text "Cancel"
            ]
        ]
    , content =
        [ S.textField
            [ A.placeholder "Name"
            , A.value item.name
            , E.onInput (SetModalState "name")

            --
            , T.max_w_xs
            , T.w_screen
            ]
            []
        ]
    , onSubmit =
        RenameItem item
    , state =
        Dict.empty
    , title =
        case item.kind of
            Directory ->
                "Rename directory"

            _ ->
                "Rename file"
    }
