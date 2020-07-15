module Drive.Modals exposing (..)

import Dict
import Drive.Item as Item exposing (Item, Kind(..))
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Modal exposing (Modal)
import Styling as S
import Tailwind as T
import Types exposing (Msg(..))



-- ⚗️


renameItem : Item -> Modal Msg
renameItem item =
    { confirmationButtons =
        [ S.button
            [ E.onClick (RenameItem item)

            --
            , T.bg_purple
            ]
            [ Html.text "Rename"
            ]

        --
        , S.button
            [ E.onClick HideModal

            --
            , T.bg_gray_500
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
            [ A.placeholder "Name"
            , A.value item.name
            , E.onInput (SetModalState "name")

            --
            , T.w_full
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
