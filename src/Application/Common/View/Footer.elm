module Common.View.Footer exposing (view)

import Authentication.External exposing (createAccountUrl)
import Common
import Common.View as Common
import Drive.Sidebar
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Maybe.Extra as Maybe
import Mode
import Routing
import Styling as S
import Tailwind as T
import Types exposing (..)
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
                case model.mode of
                    Mode.Default ->
                        [ explore ]

                    Mode.PersonalDomain ->
                        []

            Routing.Explore ->
                if Maybe.isJust model.authenticated then
                    [ myDrive model ]

                else
                    [ createAccount model ]

            -----------------------------------------
            -- Tree
            -----------------------------------------
            Routing.PersonalTree _ ->
                treeActions model

            Routing.Tree _ _ ->
                treeActions model
        )


treeActions model =
    [ if Maybe.isNothing model.authenticated then
        action
            Button
            [ A.href "TODO" ]
            FeatherIcons.user
            [ Html.text "Sign in" ]

      else
        Html.nothing

    --
    , if Common.isAuthenticatedAndNotExploring model then
        addCreateAction model

      else if Maybe.isJust model.authenticated then
        myDrive model

      else
        createAccount model

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


createAccount model =
    action
        Button
        [ A.href (createAccountUrl model.didKey model.url) ]
        FeatherIcons.user
        [ Html.text "Create account" ]


explore =
    action
        Button
        [ E.onClick (Reset Routing.Explore) ]
        FeatherIcons.hash
        [ Html.text "Explore" ]


myDrive model =
    case model.authenticated of
        Just { dnsLink } ->
            action
                Link
                [ model.url
                    |> Routing.routeUrl (Routing.Tree { root = dnsLink } [])
                    |> A.href
                ]
                FeatherIcons.hardDrive
                [ Html.text "My Drive" ]

        Nothing ->
            Html.nothing



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
