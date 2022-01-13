module Common.View.Footer exposing (view)

import Common
import Common.View as Common
import Drive.Sidebar
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Extra as Html
import Radix exposing (..)
import Result.Extra as Result
import Routing
import Styling as S
import Tailwind as T
import Url



-- 🖼


view : Model -> Html Msg
view m =
    Html.footer
        [ T.bg_base_25
        , T.pt_px

        -- Dark mode
        ------------
        , T.dark__bg_base_950
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
            , T.text_base_400
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
        , T.text_base_500
        , T.transform

        --
        , T.sm__scale_100
        ]
        (case model.route of
            Routing.Undecided ->
                [ updateAppAction model.appUpdate ]

            -----------------------------------------
            -- Tree
            -----------------------------------------
            Routing.Tree _ _ ->
                treeActions model
        )


treeActions : Model -> List (Html Msg)
treeActions model =
    let
        isAuthenticatedTree =
            Routing.isAuthenticatedTree model.authenticated model.route

        isMutableDirectory =
            not (Result.unwrap False .readOnly model.directoryList)
    in
    [ updateAppAction model.appUpdate
    , if Common.isSingleFileView model then
        Html.nothing

      else if isAuthenticatedTree then
        if isMutableDirectory then
            addCreateAction model

        else
            Html.nothing

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


addCreateAction : Model -> Html Msg
addCreateAction model =
    let
        isInAddOrCreateMode =
            case model.sidebar of
                Just (Drive.Sidebar.AddOrCreate _) ->
                    True

                _ ->
                    False
    in
    action
        Button
        [ E.onClick ToggleSidebarAddOrCreate

        --
        , if isInAddOrCreateMode then
            T.text_purple

          else
            T.text_inherit

        -- Dark mode
        ------------
        , if isInAddOrCreateMode then
            T.dark__text_white

          else
            T.dark__text_inherit
        ]
        FeatherIcons.plus
        [ Html.text "Add / Create" ]


myDrive username =
    action
        Button
        [ E.onClick (GoToRoute <| Routing.treeRootTopLevel username) ]
        FeatherIcons.hardDrive
        [ Html.text "My Drive" ]


signIn =
    action
        Button
        [ E.onClick RedirectToLobby ]
        FeatherIcons.user
        [ Html.text "Sign in" ]


updateAppAction : AppUpdate -> Html Msg
updateAppAction a =
    case a of
        NotAvailable ->
            Html.text ""

        Installing ->
            action
                Button
                [ T.opacity_75 ]
                FeatherIcons.loader
                [ Html.text "Downloading Drive update" ]

        Installed ->
            action
                Button
                [ E.onClick ReloadApplication
                , T.text_green

                -- Dark mode
                ------------
                , T.dark__opacity_80
                ]
                FeatherIcons.refreshCw
                [ Html.text "Reload to update Drive" ]



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
