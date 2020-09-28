module Common.View exposing (..)

import FeatherIcons
import FileSystem
import Html exposing (Html)
import Html.Attributes as A
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Radix exposing (Model, Msg)
import Routing
import Tailwind as T



-- EVENTS


blobUrlsDecoder : Decode.Decoder Msg
blobUrlsDecoder =
    blobUrlObjectDecoder
        |> Decode.list
        |> Decode.at [ "detail", "blobs" ]
        |> Decode.map (\blobs -> Radix.AddFiles { blobs = blobs })


blobUrlObjectDecoder : Decode.Decoder { path : String, url : String }
blobUrlObjectDecoder =
    Decode.map2
        (\path url -> { path = path, url = url })
        (Decode.field "path" Decode.string)
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


isPreppingTree : Model -> Bool
isPreppingTree m =
    case m.fileSystemStatus of
        FileSystem.Ready ->
            False

        FileSystem.AdditionalListing ->
            False

        FileSystem.Operation _ ->
            False

        FileSystem.Error _ ->
            False

        _ ->
            True


shouldShowLoadingAnimation : Model -> Bool
shouldShowLoadingAnimation m =
    m.showLoadingOverlay || (m.fileSystemStatus == FileSystem.Loading)



-- TINY VIEWS


introLogo : Html msg
introLogo =
    Html.a
        [ A.href "#/"

        --
        , T.block
        , T.max_w_sm
        , T.relative
        , T.w_full
        ]
        [ Html.div
            [ A.style "background-image" "url(images/logo/drive_full_gradient_purple_haze.svg)"
            , A.style "padding-top" "28.0386934%"
            ]
            []
        ]


introText : List (Html msg) -> Html msg
introText =
    Html.div
        [ T.max_w_xl
        , T.mt_4
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
                [ T.animate_spin
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
