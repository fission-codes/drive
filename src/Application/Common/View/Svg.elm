module Common.View.Svg exposing (..)

import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)



-- 🖼


badge : Svg msg
badge =
    svg
        [ class "fill-current"
        , height "100%"
        , width "100%"
        , viewBox "0 0 88 88"
        ]
        [ Svg.path
            [ d "M44 88a44 44 0 1 1 0-88 44 44 0 0 1 0 88zm-9-29h-6c-2 0-4-2-4-4s2-4 4-4h16l5 8 2 2c2 2 4 3 7 3 5 0 9-4 9-9s-4-9-9-9H48l-2-3h13c5 0 9-4 9-9s-4-9-9-9h-6c0-2-2-3-5-3s-6 3-6 6 3 6 6 6 5-2 5-4h6c2 0 4 2 4 4s-2 4-4 4H43l-5-7-2-2c-2-3-4-4-7-4-5 0-9 4-9 9s4 9 9 9h11l2 3H29c-5 0-9 4-9 9s4 9 9 9h5a6 6 0 1 0 1-5zm20-3l-3-5h7c2 0 4 2 4 4s-2 4-4 4l-3-2-1-1zM33 34l3 4h-7c-2 0-4-2-4-4s2-4 4-4l3 2 1 2z"
            , fillRule "nonzero"
            ]
            []
        ]


badgeOutline : Svg msg
badgeOutline =
    svg
        [ class "fill-current"
        , height "100%"
        , width "100%"
        , viewBox "0 0 88 88"
        ]
        [ Svg.path
            [ d "M44 84a40 40 0 1 0 0-80 40 40 0 0 0 0 80zm0 4a44 44 0 1 1 0-88 44 44 0 0 1 0 88zm-9-29a6 6 0 1 1-1 5h-5c-5 0-9-4-9-9s4-9 9-9h13l-2-3H29c-5 0-9-4-9-9s4-9 9-9c3 0 5 1 7 4l2 2 5 7h16c2 0 4-2 4-4s-2-4-4-4h-6c0 2-2 4-5 4s-6-3-6-6 3-6 6-6 5 1 5 3h6c5 0 9 4 9 9s-4 9-9 9H46l2 3h11c5 0 9 4 9 9s-4 9-9 9c-3 0-5-1-7-3l-2-2-5-8H29c-2 0-4 2-4 4s2 4 4 4h6zm20-3l1 1 3 2c2 0 4-2 4-4s-2-4-4-4h-7l3 5zM33 34a350 350 0 0 0-4-4c-2 0-4 2-4 4s2 4 4 4h7l-3-4z"
            , fillRule "nonzero"
            ]
            []
        ]


icon : { gradient : Maybe { id : String, svg : Svg msg } } -> Svg msg
icon { gradient } =
    svg
        [ height "100%"
        , width "100%"
        , viewBox "0 0 98 94"
        ]
        [ case gradient of
            Just { svg } ->
                Svg.defs [] [ svg ]

            Nothing ->
                Svg.text ""

        --
        , Svg.path
            [ d "M30 76a12 12 0 110 11H18a18 18 0 010-37h26l-4-6H18a18 18 0 010-37c6 0 11 2 15 7l3 5 10 14h33a8 8 0 000-15H68a12 12 0 110-11h11a18 18 0 010 37H53l4 6h22a18 18 0 11-14 30l-3-4-10-15H18a8 8 0 000 15h12zm41-6l2 4 6 2a8 8 0 000-15H65l6 9zM27 25l-3-5-6-2a8 8 0 000 15h15l-6-8z"

            --
            , case gradient of
                Just { id } ->
                    fill ("url(#" ++ id ++ ")")

                Nothing ->
                    fill "currentColor"

            --
            , fillRule "nonzero"
            ]
            []
        ]


iconPinkPurpleGradient : { id : String, svg : Svg msg }
iconPinkPurpleGradient =
    { id = "a"
    , svg =
        Svg.linearGradient
            [ x1 "25.5%", y1 "13.7%", x2 "73.1%", y2 "84.3%", id "a" ]
            [ Svg.stop [ stopColor "#FF5274", offset "0%" ] []
            , Svg.stop [ stopColor "#6446FA", offset "100%" ] []
            ]
    }


iconWhitePurpleGradient : { id : String, svg : Svg msg }
iconWhitePurpleGradient =
    { id = "a"
    , svg =
        Svg.linearGradient
            [ x1 "25.5%", y1 "13.7%", x2 "73.1%", y2 "84.3%", id "a" ]
            [ Svg.stop [ stopColor "#FFFFFF", offset "0%" ] []
            , Svg.stop [ stopColor "#6446FA", offset "100%" ] []
            ]
    }
