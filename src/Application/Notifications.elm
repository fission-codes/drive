module Notifications exposing (..)

import FeatherIcons
import Html exposing (Html)
import Tailwind as T
import Toasty



-- 🧩


type Notification msg
    = Indication (Html msg)



-- 🎛


config : Toasty.Config msg
config =
    Toasty.config
        |> Toasty.transitionOutDuration 300
        |> Toasty.containerAttrs
            [ T.bottom_0
            , T.fixed
            , T.mb_6
            , T.mr_6
            , T.right_0
            , T.text_sm
            , T.z_50
            ]
        |> Toasty.itemAttrs
            [ T.bg_gray_300
            , T.mt_3
            , T.p_4
            , T.rounded
            , T.shadow_md
            , T.text_gray_900
            ]



-- 📣


loadingIndication : String -> Notification msg
loadingIndication text =
    [ FeatherIcons.loader
        |> FeatherIcons.withSize 14
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div
            [ T.animate_spin
            , T.text_gray_900
            ]
        |> List.singleton
        |> Html.div []

    --
    , Html.div
        [ T.ml_2 ]
        [ Html.text text ]
    ]
        |> Html.div [ T.flex, T.items_center ]
        |> Indication



-- 🖼


view : Notification msg -> Html msg
view notification =
    case notification of
        Indication html ->
            html
