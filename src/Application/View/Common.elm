module View.Common exposing (..)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Tailwind as T



-- FADES


fadeOutLeft : Html.Attribute msg
fadeOutLeft =
    A.style
        "-webkit-mask-image"
        "linear-gradient(90deg, rgba(0, 0, 0, 0.325) 0%, rgb(0, 0, 0) 20%, rgb(0, 0, 0) 100%)"


fadeOutRight : Html.Attribute msg
fadeOutRight =
    A.style
        "-webkit-mask-image"
        "linear-gradient(90deg, rgb(0, 0, 0) 0%, rgb(0, 0, 0) 80%, rgb(0, 0, 0, 0.325) 100%)"



-- TINY VIEWS


loadingAnimation : Html msg
loadingAnimation =
    FeatherIcons.loader
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div [ T.animation_spin ]
