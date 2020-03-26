module Drive.View.Common exposing (..)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Drive.Item exposing (Kind(..))
import List.Extra as List
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
import Url.Builder



-- SIDEBAR


sidebarControls : { above : Bool, expanded : Bool } -> Html Msg
sidebarControls { above, expanded } =
    let
        additionalAttributes =
            if above then
                [ T.absolute
                , T.left_0
                , T.right_0
                , T.top_0
                , T.z_30

                --
                , S.default_transition_duration
                , S.default_transition_easing
                , T.opacity_0
                , T.transition
                , T.transition_opacity

                --
                , T.group_hover__opacity_100
                ]

            else
                [ T.relative ]
    in
    Html.div
        (List.append
            [ T.flex
            , T.items_center
            , T.justify_end
            , T.mt_px
            , T.px_2
            , T.pt_px
            , T.text_gray_300
            , T.text_sm
            ]
            additionalAttributes
        )
        [ Html.div
            [ T.absolute
            , T.border_b
            , T.border_gray_300
            , T.left_0
            , T.opacity_10
            , T.top_full
            , T.right_0
            ]
            []

        --
        , Html.div
            [ E.onClick ToggleExpandedSidebar

            --
            , T.cursor_pointer
            , T.hidden
            , T.items_center
            , T.px_2
            , T.py_3

            --
            , T.md__flex
            ]
            [ (if expanded then
                FeatherIcons.minimize2

               else
                FeatherIcons.maximize2
              )
                |> FeatherIcons.withSize 14
                |> FeatherIcons.toHtml [ A.style "margin" "0 auto" ]
                |> List.singleton
                |> Html.div [ T.flex_shrink_0, T.w_6 ]

            --
            , Html.div
                [ T.ml_1 ]
                [ if expanded then
                    Html.text "Minimize"

                  else
                    Html.text "Maximize"
                ]
            ]

        --
        , Html.div
            [ E.onClick CloseSidebar

            --
            , T.cursor_pointer
            , T.flex
            , T.items_center
            , T.px_2
            , T.py_3
            ]
            [ FeatherIcons.x
                |> FeatherIcons.withSize 18
                |> FeatherIcons.toHtml [ A.style "margin" "0 auto" ]
                |> List.singleton
                |> Html.div [ T.flex_shrink_0, T.w_6 ]

            --
            , Html.div
                [ T.ml_1 ]
                [ Html.text "Close" ]
            ]
        ]
