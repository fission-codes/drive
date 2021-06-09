module View exposing (view)

import Authentication.View as Authentication
import Browser
import Common.View as Common
import Common.View.ContextMenu
import Common.View.HelpfulNote
import ContextMenu exposing (ContextMenu)
import Drive.Item exposing (Kind(..))
import Drive.View as Drive
import FileSystem
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Ext as E
import Html.Events.Extra.Drag as Drag
import Html.Extra as Html
import Html.Lazy as Lazy
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Modal exposing (Modal)
import Notifications
import Radix exposing (..)
import Routing
import Tailwind as T
import Toasty
import Url.Builder



-- 🖼


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Drive"
    , body = body model
    }


body : Model -> List (Html Msg)
body m =
    [ -----------------------------------------
      -- Main
      -----------------------------------------
      case ( Common.shouldShowLoadingAnimation m, m.route ) of
        ( True, _ ) ->
            case ( m.initialised, m.fileSystemStatus ) of
                ( Err "UNSUPPORTED_BROWSER", _ ) ->
                    errorView
                        [ Html.div
                            [ T.text_xl, T.text_purple ]
                            [ Html.text "This browser, or browser mode, is not supported." ]
                        , Html.div
                            [ T.mt_2, T.opacity_40, T.text_sm ]
                            [ Html.text "Maybe "
                            , Html.a
                                [ A.href "https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API"
                                , T.underline
                                ]
                                [ Html.text "IndexedDB" ]
                            , Html.text " is not working here?"
                            ]
                        ]

                ( Err err, _ ) ->
                    errorView
                        [ Html.text err ]

                ( Ok False, _ ) ->
                    Common.loadingScreen
                        [ Common.loadingText "Just a moment, loading the application." ]

                ( Ok True, FileSystem.Loading ) ->
                    Common.loadingScreen
                        [ Common.loadingText "Just a moment, loading the filesystem." ]

                ( Ok True, _ ) ->
                    Common.loadingScreen
                        []

        ( _, Routing.Undecided ) ->
            Authentication.notAuthenticated m

        -----------------------------------------
        -- Tree
        -----------------------------------------
        ( _, Routing.Tree _ _ ) ->
            treeView m

    -----------------------------------------
    -- Context Menu
    -----------------------------------------
    , case m.contextMenu of
        Just menu ->
            Common.View.ContextMenu.view menu

        Nothing ->
            Html.nothing

    -----------------------------------------
    -- Modal
    -----------------------------------------
    , case m.modal of
        Just modal ->
            Modal.view modal

        Nothing ->
            Html.nothing

    -----------------------------------------
    -- Helpful Note
    -----------------------------------------
    -- Is shown, for example, when dragging files onto Fission Drive.
    , case m.helpfulNote of
        Just note ->
            Common.View.HelpfulNote.view note

        Nothing ->
            Html.nothing

    -----------------------------------------
    -- Notifications
    -----------------------------------------
    , Lazy.lazy
        (Toasty.view Notifications.config Notifications.view ToastyMsg)
        m.toasties

    -----------------------------------------
    -- Overlay
    -----------------------------------------
    , Lazy.lazy3
        overlay
        m.contextMenu
        m.helpfulNote
        m.modal
    ]
        |> Html.node
            "fs-drop-zone"
            (if Routing.isAuthenticatedTree m.authenticated m.route then
                { onOver = \_ -> ShowHelpfulNote "Drop to add it to your drive"
                , onDrop = \_ -> HideHelpfulNote
                , onEnter = Nothing
                , onLeave = Nothing
                }
                    |> Drag.onFileFromOS
                    |> List.append [ E.on "dropBlobs" Common.blobUrlsDecoder ]
                    |> List.append (rootAttributes m)

             else
                rootAttributes m
            )
        |> List.singleton


rootAttributes : Model -> List (Html.Attribute Msg)
rootAttributes m =
    List.append
        (case m.contextMenu of
            Just _ ->
                [ E.onTap RemoveContextMenu ]

            Nothing ->
                []
        )
        [ E.on "focusout" (Decode.succeed Blurred)
        , E.on "focusin" (Decode.succeed Focused)
        ]


treeView : Model -> Html Msg
treeView m =
    if Common.isPreppingTree m then
        "Just a moment, loading the directory."
            |> Common.loadingText
            |> List.singleton
            |> Common.loadingScreen

    else
        Drive.view m


errorView nodes =
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
            nodes
        ]



-- OVERLAY


overlay : Maybe (ContextMenu Msg) -> Maybe { faded : Bool, note : String } -> Maybe (Modal Msg) -> Html Msg
overlay contextMenu helpfulNote modal =
    let
        shouldBeShown =
            False
                || Maybe.isJust contextMenu
                || Maybe.unwrap False (.faded >> not) helpfulNote
                || Maybe.isJust modal
    in
    Html.div
        [ T.fixed
        , T.bg_black
        , T.duration_200
        , T.ease_in_out
        , T.inset_0
        , T.transition_opacity
        , T.transform
        , T.translate_x_0
        , T.z_40

        --
        , if shouldBeShown then
            T.opacity_40

          else
            T.opacity_0

        --
        , if shouldBeShown then
            T.pointer_events_auto

          else
            T.pointer_events_none
        ]
        []
