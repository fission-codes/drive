module Common.View exposing (..)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Ipfs
import Json.Decode as Decode
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
        ( Nothing, _ ) ->
            True

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
