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

        ( Just _, Ipfs.FileSystemOperation ) ->
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
        , T.leading_tight
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
                [ T.absolute
                , T.bg_pink
                , T.font_body
                , T.font_semibold
                , T.leading_relaxed
                , T.px_1
                , T.right_0
                , T.rounded
                , T.subpixel_antialiased
                , T.top_0
                , T.tracking_wider
                , T.transform
                , T.translate_x_5
                , T.translate_y_1
                , T.text_white
                , T.text_xs
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


loadingAnimation : Html msg
loadingAnimation =
    FeatherIcons.loader
        |> FeatherIcons.withSize 24
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.span
            [ T.animation_spin
            , T.inline_block
            , T.text_gray_300
            ]
