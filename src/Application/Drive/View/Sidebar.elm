module Drive.View.Sidebar exposing (view)

import Common
import Common.View as Common
import Common.View.Footer as Footer
import Drive.View.Details as Details
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html exposing (nothing)
import Html.Lazy
import Item exposing (Item, Kind(..))
import List.Extra as List
import Maybe.Extra as Maybe
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Time
import Time.Distance
import Types exposing (..)
import Url.Builder



-- 🖼


view : Model -> Html Msg
view model =
    case model.selectedCid of
        Just _ ->
            view_ model

        Nothing ->
            nothing


{-| NOTE: This is positioned using `position: sticky` and using fixed px values. Kind of a hack, and should be done in a better way, but I haven't found one.
-}
view_ : Model -> Html Msg
view_ model =
    Html.div
        [ A.style "height" "calc(100vh - 99px - 32px * 2 - 92px - 2px)"
        , A.style "top" "131px"

        --
        , T.flex
        , T.flex_col
        , T.group
        , T.h_screen
        , T.items_center
        , T.justify_center
        , T.overflow_hidden
        , T.px_4
        , T.py_6
        , T.rounded_md
        , T.sticky
        , T.w_full

        --
        , if Maybe.isJust model.selectedCid then
            T.bg_gray_900

          else
            T.bg_transparent

        --
        , if model.largePreview && Maybe.isJust model.selectedCid then
            T.md__w_full

          else
            T.md__w_1over2

        -- Dark mode
        ------------
        , if Maybe.isJust model.selectedCid then
            T.dark__bg_darkness_below

          else
            T.dark__bg_transparent
        ]
        [ model.selectedCid
            |> Maybe.andThen
                (\cid ->
                    model.directoryList
                        |> Result.withDefault []
                        |> List.find (.path >> (==) cid)
                )
            |> Maybe.map
                (Html.Lazy.lazy5
                    Details.view
                    model.currentTime
                    (Common.base model)
                    model.largePreview
                    model.showPreviewOverlay
                )
            |> Maybe.withDefault
                nothing
        ]



-- ACTIONS
--
--
-- fileSystemActions =
--     Html.div
--         [ T.hidden
--         , T.items_center
--         , T.justify_center
--
--         --
--         , T.md__flex
--         ]
--         [ Html.div
--             [ T.border
--             , T.border_gray_700
--             , T.rounded
--             , T.text_gray_300
--
--             -- Dark mode
--             ------------
--             , T.dark__border_darkness_above
--             , T.dark__text_gray_400
--             ]
--             [ highlightedAction FeatherIcons.uploadCloud "Add files"
--             , action FeatherIcons.folderPlus "Create directory"
--             , action FeatherIcons.folder "Share directory"
--             ]
--         ]
--
--
-- highlightedAction =
--     action_ True
--
--
-- action =
--     action_ False
--
--
-- action_ highlight ico lbl =
--     Html.div
--         [ T.border_b
--         , T.border_gray_700
--         , T.flex
--         , T.items_center
--         , T.mt_px
--         , T.pl_5
--         , T.pr_16
--         , T.py_4
--
--         --
--         , T.last__border_b_0
--
--         --
--         , if highlight then
--             T.font_semibold
--
--           else
--             T.font_normal
--
--         -- Dark mode
--         ------------
--         , T.dark__border_darkness_above
--
--         --
--         , if highlight then
--             T.dark__text_gray_500
--
--           else
--             T.dark__text_inherit
--         ]
--         [ ico
--             |> FeatherIcons.withSize 16
--             |> FeatherIcons.toHtml []
--
--         --
--         , Html.span
--             [ T.ml_3 ]
--             [ Html.text lbl ]
--         ]
--
