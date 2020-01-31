module View exposing (view)

import Browser
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Ipfs
import Item exposing (Item, Kind(..))
import List.Extra as List
import Maybe.Extra as Maybe
import Routing exposing (Page(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
import Url.Builder
import View.Common as Common
import View.Drive as Drive
import View.Explore as Explore



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body = body model
    }


body : Model -> List (Html Msg)
body m =
    if m.ipfs == Ipfs.Connecting then
        [ Html.div
            [ T.absolute
            , T.left_1over2
            , T.neg_translate_y_1over2
            , T.top_1over2
            ]
            [ Common.loadingAnimation ]
        ]

    else if m.ipfs /= Ipfs.Ready || Maybe.isNothing m.rootCid then
        [ Explore.view m ]

    else
        [ Drive.view m ]
