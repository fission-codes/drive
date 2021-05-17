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
            Common.loadingScreen
                (if m.fileSystemStatus == FileSystem.Loading then
                    [ Common.loadingText "Loading filesystem" ]

                 else if m.fileSystemCid == Nothing then
                    [ Common.loadingText "Just a moment, loading the filesystem." ]

                 else
                    []
                )

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
