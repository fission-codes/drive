module View exposing (view)

import Browser
import Common.View as Common
import Common.View.ContextMenu
import Drive.View as Drive
import Explore.View as Explore
import Html exposing (Html)
import Html.Events as E
import Html.Extra as Html
import Item exposing (Kind(..))
import Json.Decode as Decode
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
    [ -----------------------------------------
      -- Main
      -----------------------------------------
      if Common.shouldShowLoadingAnimation m then
        Html.div
            [ T.absolute
            , T.left_1over2
            , T.neg_translate_y_1over2
            , T.top_1over2
            ]
            [ Common.loadingAnimation ]

      else if Common.shouldShowExplore m then
        Explore.view m

      else
        Drive.view m

    -----------------------------------------
    -- Extra
    -----------------------------------------
    , case m.contextMenu of
        Just menu ->
            Common.View.ContextMenu.view menu

        Nothing ->
            Html.nothing
    ]
        |> Html.div
            [ E.on "focusout" (Decode.succeed Blurred)
            , E.on "focusin" (Decode.succeed Focused)

            --
            , case m.contextMenu of
                Just _ ->
                    E.onClick HideContextMenu

                Nothing ->
                    E.onClick Bypass
            ]
        |> List.singleton
