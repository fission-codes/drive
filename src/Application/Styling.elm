module Styling exposing (..)

import Html exposing (Html)
import Tailwind as T



-- 🧩


type alias Node msg =
    List (Html.Attribute msg) -> List (Html msg) -> Html msg



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


button : Node msg
button =
    buttonWithNode Html.button


buttonLink : Node msg
buttonLink =
    buttonWithNode Html.a


buttonWithNode : Node msg -> Node msg
buttonWithNode node attributes =
    attributes
        |> List.append
            [ T.antialiased
            , T.appearance_none
            , T.font_semibold
            , T.leading_normal
            , T.px_5
            , T.py_3
            , T.relative
            , T.rounded
            , T.text_white
            , T.tracking_wider
            , T.transition_colors
            , T.uppercase

            --
            , default_transition_duration
            , default_transition_easing

            --
            , T.focus__shadow_outline
            ]
        |> node


label : Node msg
label attributes =
    attributes
        |> List.append
            [ T.block
            , T.font_bold
            , T.pb_1
            , T.text_gray_200
            , T.text_xs
            , T.tracking_wide
            , T.uppercase

            -- Dark mode
            ------------
            , T.dark__text_gray_300
            ]
        |> Html.label


textField : Node msg
textField attributes =
    attributes
        |> List.append
            [ T.appearance_none
            , T.bg_transparent
            , T.border_2
            , T.border_gray_500
            , T.flex_auto
            , T.leading_relaxed
            , T.outline_none
            , T.px_4
            , T.py_2
            , T.rounded
            , T.text_inherit
            , T.text_base

            -- Dark mode
            ------------
            , T.dark__border_gray_200
            ]
        |> Html.input
