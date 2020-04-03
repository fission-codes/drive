module Styling exposing (..)

import Html exposing (Html)
import Tailwind as T



-- 🖼


container_padding =
    T.px_6


default_light_text_color =
    T.text_gray_100


default_dark_text_color =
    T.dark__text_gray_500


default_transition_duration =
    T.duration_500


default_transition_easing =
    T.ease_out


iconSize =
    22



-- 🍱


button : List (Html.Attribute msg) -> List (Html msg) -> Html msg
button attributes =
    attributes
        |> List.append
            [ T.antialiased
            , T.appearance_none
            , T.font_semibold
            , T.leading_normal
            , T.ml_3
            , T.px_5
            , T.py_3
            , T.relative
            , T.rounded
            , T.text_sm
            , T.text_white
            , T.tracking_wider
            , T.uppercase

            --
            , T.focus__shadow_outline
            ]
        |> Html.button
