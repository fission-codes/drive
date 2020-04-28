module Common.View exposing (..)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Ipfs
import Json.Decode as Decode
import Routing
import Tailwind as T
import Types exposing (Model, Msg)



-- EVENTS


blobUrlsDecoder : Decode.Decoder Msg
blobUrlsDecoder =
    blobUrlObjectDecoder
        |> Decode.list
        |> Decode.at [ "detail", "blobs" ]
        |> Decode.map (\blobs -> Types.AddFiles { blobs = blobs })


blobUrlObjectDecoder : Decode.Decoder { name : String, url : String }
blobUrlObjectDecoder =
    Decode.map2
        (\name url -> { name = name, url = url })
        (Decode.field "name" Decode.string)
        (Decode.field "url" Decode.string)



-- FADES


fadeOutLeft : Html.Attribute msg
fadeOutLeft =
    A.style
        "-webkit-mask-image"
        "linear-gradient(90deg, rgba(0, 0, 0, 0) 0%, rgb(0, 0, 0) 25%, rgb(0, 0, 0) 100%)"


fadeOutRight : Html.Attribute msg
fadeOutRight =
    A.style
        "-webkit-mask-image"
        "linear-gradient(90deg, rgb(0, 0, 0) 0%, rgb(0, 0, 0) 75%, rgb(0, 0, 0, 0) 100%)"



-- STATES


shouldShowExplore : Model -> Bool
shouldShowExplore m =
    case ( m.foundation, m.ipfs ) of
        ( Just _, Ipfs.Ready ) ->
            False

        ( Just _, Ipfs.AdditionalListing ) ->
            False

        ( Just _, Ipfs.FileSystemOperation _ ) ->
            False

        _ ->
            True


shouldShowLoadingAnimation : Model -> Bool
shouldShowLoadingAnimation m =
    m.ipfs == Ipfs.Connecting || m.showLoadingOverlay



-- TINY VIEWS


introLogo : Html msg
introLogo =
    Html.div
        [ T.antialiased
        , T.font_display
        , T.font_light
        , T.leading_none
        , T.tracking_widest
        , T.text_6xl
        , T.uppercase
        ]
        [ Html.span
            []
            [ Html.text "Fission " ]
        , Html.span
            [ T.relative ]
            [ Html.text "Drive"
            , Html.div
                [ A.style "font-size" "11.5px"
                , A.style "letter-spacing" "1.5px"
                , A.style "padding" "0px 3px 0 4px"

                --
                , T.absolute
                , T.bg_gray_300
                , T.font_body
                , T.font_normal
                , T.leading_relaxed
                , T.mt_px
                , T.px_1
                , T.right_0
                , T.rounded_sm
                , T.subpixel_antialiased
                , T.top_0
                , T.tracking_wider
                , T.transform
                , T.translate_x_5
                , T.translate_y_1
                , T.text_gray_600
                , T.text_xs

                -- Dark mode
                ------------
                , T.dark__bg_gray_200
                , T.dark__text_gray_400
                ]
                [ Html.text "BETA" ]
            ]
        ]


introText : List (Html msg) -> Html msg
introText =
    Html.div
        [ T.max_w_xl
        , T.mt_5
        , T.text_gray_300

        -- Dark mode
        ------------
        , T.dark__text_gray_400
        ]


loadingAnimation : { size : Int } -> Html msg
loadingAnimation =
    loadingAnimationWithAttributes [ T.text_gray_300 ]


loadingAnimationWithAttributes : List (Html.Attribute msg) -> { size : Int } -> Html msg
loadingAnimationWithAttributes attributes { size } =
    FeatherIcons.loader
        |> FeatherIcons.withSize (toFloat size)
        |> wrapIcon
            (List.append
                [ T.animation_spin
                , T.block
                ]
                attributes
            )


loadingScreen : List (Html msg) -> Html msg
loadingScreen additionalNodes =
    Html.div
        [ T.flex
        , T.flex_col
        , T.min_h_screen
        ]
        [ Html.div
            [ T.flex
            , T.flex_auto
            , T.flex_col
            , T.items_center
            , T.justify_center
            , T.p_8
            , T.text_center
            ]
            (loadingAnimation { size = 24 } :: additionalNodes)
        ]


wrapIcon : List (Html.Attribute msg) -> FeatherIcons.Icon -> Html msg
wrapIcon attributes icon =
    Html.span attributes [ FeatherIcons.toHtml [] icon ]
