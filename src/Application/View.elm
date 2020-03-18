module View exposing (view)

import Browser
import Common.View as Common
import Drive.View as Drive
import Explore.View as Explore
import Html exposing (Html)
import Item exposing (Kind(..))
import Routing exposing (Route(..))
import Tailwind as T
import Types exposing (..)
import Url.Builder



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body = body model
    }


body : Model -> List (Html Msg)
body m =
    if Common.shouldShowLoadingAnimation m then
        [ Html.div
            [ T.absolute
            , T.left_1over2
            , T.neg_translate_y_1over2
            , T.top_1over2
            ]
            [ Common.loadingAnimation ]
        ]

    else if Common.shouldShowExplore m then
        [ Explore.view m ]

    else
        [ Drive.view m ]
