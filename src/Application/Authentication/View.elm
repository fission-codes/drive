module Authentication.View exposing (..)

import Common.View as Common
import Common.View.Footer as Footer
import Common.View.Svg
import FeatherIcons
import Html exposing (Html)
import Html.Extra as Html
import Styling as S
import Tailwind as T
import Types exposing (..)



-- 🖼


notAuthenticated : Model -> Html Msg
notAuthenticated model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen
        ]
        [ Html.div
            [ S.container_padding
            , T.flex
            , T.flex_auto
            , T.flex_col
            , T.items_center
            , T.justify_center
            , T.text_center
            ]
            [ Common.introLogo
            , Common.introText
                [ Html.text "Fission Drive is your web native file system."
                , Html.br [] []
                , Html.text "Your files, under your control, available everywhere."
                ]

            --
            , Html.div
                [ T.flex, T.mt_8 ]
                [ S.button
                    [ T.bg_purple, T.flex, T.items_center ]
                    [ Html.span
                        [ T.mr_2
                        , T.opacity_30
                        , T.text_white
                        , T.w_4
                        ]
                        [ Common.View.Svg.icon
                            { gradient = Nothing }
                        ]

                    --
                    , Html.text "Create an account"
                    ]

                --
                , S.button
                    [ T.bg_gray_200
                    , T.opacity_25
                    , T.pointer_events_none
                    ]
                    [ Html.text "Sign in" ]
                ]
            ]

        --
        , Footer.view model
        ]


signIn : Html Msg
signIn =
    -- TODO
    Html.nothing


signUp : Html Msg
signUp =
    Common.introLogo
