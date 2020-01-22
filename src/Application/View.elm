module View exposing (view)

import Browser
import Html
import Tailwind as T
import Types exposing (..)



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body =
        [ Html.div
            [ T.font_bold
            , T.mt_8
            , T.text_center
            , T.text_5xl
            ]
            [ Html.text "Fission Drive" ]
        ]
    }
