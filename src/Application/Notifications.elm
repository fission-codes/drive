module Notifications exposing (Notification, config, loadingIndication, text, view)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Tailwind as T
import Toasty



-- 🧩


type Notification msg
    = Indication (Html msg)



-- 🎛


config : Toasty.Config msg
config =
    Toasty.config
        |> Toasty.transitionOutDuration 350
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
            [ A.style "opacity" "1"
            , T.block
            , T.duration_300
            , T.transition_opacity
            ]
        |> Toasty.transitionOutAttrs
            [ A.style "opacity" "0" ]



-- 📣


loadingIndication : String -> Notification msg
loadingIndication string =
    [ FeatherIcons.loader
        |> FeatherIcons.withSize 14
        |> FeatherIcons.toHtml []
        |> List.singleton
        |> Html.div
            [ T.animate_spin
            , T.text_base_50
            ]
        |> List.singleton
        |> Html.div []

    --
    , Html.div
        [ T.ml_2 ]
        [ Html.text string ]
    ]
        |> Html.div [ T.flex, T.items_center ]
        |> Indication


text : String -> Notification msg
text string =
    string
        |> Html.text
        |> Indication



-- 🖼


view : Notification msg -> Html msg
view notification =
    case notification of
        Indication html ->
            Html.div
                [ T.bg_base_600
                , T.text_base_50

                --
                , T.mt_3
                , T.p_4
                , T.rounded
                , T.shadow_md
                ]
                [ html ]
