module Common.View.Footer exposing (view)

import Authentication.Essentials as Authentication
import Common
import Common.View as Common
import Drive.Sidebar
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Maybe.Extra as Maybe
import Radix exposing (..)
import Routing
import Styling as S
import Tailwind as T
import Url



-- 🖼


view : Model -> Html Msg
view m =
    Html.footer
        [ T.bg_gray_900
        , T.pt_px

        -- Dark mode
        ------------
        , T.dark__bg_darkness_below
        ]
        [ Html.div
            [ T.container
            , S.container_padding
            , T.flex
            , T.items_center
            , T.mx_auto
            , T.mt_px
            , T.overflow_hidden
            , T.py_8
            ]
            [ left

            --
            , Html.div
                [ T.flex_auto, T.hidden, T.md__block ]
                []

            --
            , right m
            ]
        ]



-- ㊙️


left : Html Msg
left =
    Html.div
        [ T.hidden
        , T.items_center

        --
        , T.md__flex
        ]
        [ -----------------------------------------
          -- Logo
          -----------------------------------------
          Html.img
            [ A.src "images/logo/drive_short_gradient_purple_haze.svg"
            , A.width 30

            --
            , T.opacity_70
            ]
            []

        -----------------------------------------
        -- App name
        -----------------------------------------
        , Html.span
            [ T.font_bold
            , T.font_display
            , T.leading_tight
            , T.ml_2
            , T.text_gray_400
            , T.text_sm
            , T.tracking_wider
            , T.uppercase
            ]
            [ Html.text "Fission Drive" ]
        ]


right : Model -> Html Msg
right model =
    Html.div
        [ T.flex
        , T.items_center
        , T.origin_left
        , T.scale_95
        , T.text_gray_300
        , T.transform

        --
        , T.sm__scale_100
        ]
        (case model.route of
            Routing.Undecided ->
                []

            -----------------------------------------
            -- Tree
            -----------------------------------------
            Routing.Tree _ _ ->
                treeActions model
        )


treeActions model =
    let
        isAuthenticatedTree =
            Routing.isAuthenticatedTree model.authenticated model.route
    in
    [ if isAuthenticatedTree then
        addCreateAction model

      else
        case model.authenticated of
            Just a ->
                myDrive a.username

            Nothing ->
                signIn

    --
    , action
        Button
        [ { clip = Url.toString model.url
          , notification = "Copied Drive URL to clipboard."
          }
            |> CopyToClipboard
            |> E.onClick
        ]
        FeatherIcons.share2
        [ Html.text "Copy Link" ]
    ]



-- ACTIONS


addCreateAction model =
    action
        Button
        [ E.onClick (ToggleSidebarMode Drive.Sidebar.AddOrCreate)

        --
        , if model.sidebarMode == Drive.Sidebar.AddOrCreate then
            T.text_purple

          else
            T.text_inherit

        -- Dark mode
        ------------
        , if model.sidebarMode == Drive.Sidebar.AddOrCreate then
            T.dark__text_white

          else
            T.dark__text_inherit
        ]
        FeatherIcons.plus
        [ Html.text "Add / Create" ]


myDrive username =
    action
        Button
        [ E.onClick (GoToRoute <| Routing.Tree { root = username } []) ]
        FeatherIcons.hardDrive
        [ Html.text "My Drive" ]


signIn =
    action
        Button
        [ E.onClick RedirectToLobby ]
        FeatherIcons.user
        [ Html.text "Sign in" ]



-- 🛠


type Action
    = Button
    | Link


action : Action -> List (Html.Attribute Msg) -> FeatherIcons.Icon -> List (Html Msg) -> Html Msg
action a attributes icon nodes =
    (case a of
        Button ->
            Html.span

        Link ->
            Html.a
    )
        (List.append
            attributes
            [ T.cursor_pointer
            , T.inline_flex
            , T.items_center
            , T.leading_tight
            , T.mr_8
            , T.tracking_tight

            --
            , T.last__mr_0
            ]
        )
        [ icon
            |> FeatherIcons.withSize S.iconSize
            |> FeatherIcons.toHtml []

        --
        , Html.span
            [ T.ml_2, T.truncate ]
            nodes
        ]
