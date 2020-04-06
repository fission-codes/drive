module View exposing (view)

import Authentication.View as Authentication
import Browser
import Common.View as Common
import Common.View.ContextMenu
import Common.View.HelpfulNote
import ContextMenu exposing (ContextMenu)
import Drive.Item exposing (Kind(..))
import Drive.View as Drive
import Explore.View as Explore
import Html exposing (Html)
import Html.Events as E
import Html.Events.Extra.Drag as Drag
import Html.Extra as Html
import Html.Lazy as Lazy
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Types exposing (..)
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
            Html.div
                [ T.absolute
                , T.left_1over2
                , T.neg_translate_y_1over2
                , T.top_1over2
                ]
                [ Common.loadingAnimation ]

        ( _, CreateAccount context ) ->
            Authentication.signUp context m

        ( _, Explore ) ->
            Explore.view m

        ( _, Tree _ _ ) ->
            if Common.shouldShowExplore m then
                Explore.view m

            else
                Drive.view m

        ( _, Undecided ) ->
            Authentication.notAuthenticated m

    -----------------------------------------
    -- Context Menu
    -----------------------------------------
    , case m.contextMenu of
        Just menu ->
            Common.View.ContextMenu.view menu

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

    -- Overlay
    , Lazy.lazy2
        overlay
        m.contextMenu
        m.helpfulNote
    ]
        |> Html.node
            "fs-drop-zone"
            (case m.route of
                Tree _ _ ->
                    { onOver = \_ -> ShowHelpfulNote "Drop to add it to your drive"
                    , onDrop = \_ -> HideHelpfulNote
                    , onEnter = Nothing
                    , onLeave = Nothing
                    }
                        |> Drag.onFileFromOS
                        |> List.append [ E.on "dropBlobs" Common.blobUrlsDecoder ]
                        |> List.append (rootAttributes m)

                _ ->
                    rootAttributes m
            )
        |> List.singleton


rootAttributes : Model -> List (Html.Attribute Msg)
rootAttributes m =
    [ E.on "focusout" (Decode.succeed Blurred)
    , E.on "focusin" (Decode.succeed Focused)

    --
    , case m.contextMenu of
        Just _ ->
            E.onClick RemoveContextMenu

        Nothing ->
            E.onClick Bypass
    ]



-- OVERLAY


overlay : Maybe (ContextMenu Msg) -> Maybe { faded : Bool, note : String } -> Html Msg
overlay contextMenu helpfulNote =
    let
        shouldBeShown =
            Maybe.isJust contextMenu || Maybe.unwrap False (.faded >> not) helpfulNote
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
