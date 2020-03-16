module View exposing (view)

import Browser
import Common.View as Common
import Drive.View as Drive
import Explore.View as Explore
import Html exposing (Html)
import Ipfs
import Item exposing (Kind(..))
import Maybe.Extra as Maybe
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
    if m.ipfs == Ipfs.Connecting || m.showLoadingOverlay then
        [ Html.div
            [ T.absolute
            , T.left_1over2
            , T.neg_translate_y_1over2
            , T.top_1over2
            ]
            [ Common.loadingAnimation ]
        ]

    else if shouldShowExplore m.ipfs || Maybe.isNothing m.foundation then
        [ Explore.view m ]

    else
        [ Drive.view m ]


shouldShowExplore : Ipfs.Status -> Bool
shouldShowExplore ipfsStatus =
    case ipfsStatus of
        Ipfs.Ready ->
            False

        Ipfs.AdditionalListing ->
            False

        _ ->
            True
