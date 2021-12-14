module Drive.View.Sidebar exposing (view)

import Common exposing (ifThenElse)
import Common.View as Common
import ContextMenu
import Drive.ContextMenu
import Drive.Item exposing (Kind(..))
import Drive.Item.Inventory
import Drive.Sidebar as Sidebar
import Drive.View.Common as Drive
import Drive.View.Details as Details
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Events.Extra as E
import Html.Events.Extra.Mouse as M
import Html.Extra as Html exposing (nothing)
import Html.Lazy
import Json.Decode as Decode
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Result.Extra as Result
import Routing exposing (Route(..))
import Styling as S
import Tailwind as T
import Webnative.Path exposing (Encapsulated, Path)



-- 🖼


view : Model -> Html Msg
view model =
    case model.sidebar of
        Just (Sidebar.AddOrCreate addOrCreateModel) ->
            viewSidebar
                { scrollable = True
                , expanded = model.sidebarExpanded
                , body = addOrCreate addOrCreateModel model
                }

        Just (Sidebar.Details details) ->
            viewSidebar
                { scrollable = False
                , expanded = model.sidebarExpanded
                , body = detailsForSelection details model
                }

        Just (Sidebar.EditPlaintext { editor }) ->
            viewSidebar
                { scrollable = False
                , expanded = model.sidebarExpanded
                , body = plaintextEditor editor model
                }

        Nothing ->
            nothing


{-| NOTE: This is positioned using `position: sticky` and using fixed px values. Kind of a hack, and should be done in a better way, but I haven't found one.
-}
viewSidebar : { scrollable : Bool, expanded : Bool, body : Html Msg } -> Html Msg
viewSidebar { scrollable, expanded, body } =
    Html.div
        [ A.class "sidebar"

        --
        , T.bg_base_25
        , T.group
        , T.h_screen
        , T.overflow_x_hidden
        , T.rounded_md
        , T.sticky
        , T.transform
        , T.translate_x_0
        , T.w_full

        --
        , if expanded then
            T.md__w_full

          else
            T.md__w_1over2

        --
        , if scrollable then
            T.overflow_y_auto

          else
            T.overflow_y_hidden

        -- Dark mode
        ------------
        , T.dark__bg_base_950
        ]
        [ body ]


plaintextEditor : Maybe Sidebar.EditorModel -> Model -> Html Msg
plaintextEditor maybeEditor model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.h_full
        , T.items_stretch
        ]
        [ Drive.sidebarControls
            { above = False
            , controls = editorHeaderItems model
            }

        --
        , case maybeEditor of
            Just editor ->
                Html.textarea
                    [ E.onInput (SidebarMsg << Sidebar.PlaintextEditorInput)
                    , onCtrlS (SidebarMsg Sidebar.PlaintextEditorSave)

                    --
                    , T.bg_transparent
                    , T.flex_grow
                    , T.font_mono
                    , T.px_5
                    , T.pt_5
                    , T.resize_none
                    , T.text_base_800

                    --
                    , T.h_full
                    , T.w_full

                    -- Focus Styles
                    ---------------
                    , T.appearance_none
                    , T.outline_none

                    -- Responsive
                    -------------
                    , T.sm__px_8
                    , T.sm__py_8

                    -- Dark mode
                    ------------
                    , T.dark__text_base_500
                    ]
                    [ Html.text editor.text ]

            Nothing ->
                Html.div
                    [ T.flex_grow

                    --
                    , T.h_full
                    , T.w_full
                    ]
                    [ Html.span
                        [ T.absolute
                        , T.left_1over2
                        , T.top_1over2
                        , T.transform
                        , T.neg_translate_x_1over2
                        , T.neg_translate_y_1over2
                        ]
                        [ Common.loadingAnimationWithAttributes
                            [ T.text_base_500 ]
                            { size = 24 }
                        ]
                    ]
        , Html.div
            [ T.border_t
            , T.border_base_400
            , T.border_opacity_10
            , T.flex
            , T.flex_shrink_0
            , T.p_3
            , T.relative
            , T.space_x_2
            ]
            (maybeEditor
                |> Maybe.map editorFooterItems
                |> Maybe.withDefault []
            )
        ]


editorHeaderItems : Model -> List (Html Msg)
editorHeaderItems model =
    let
        dotsIcon =
            FeatherIcons.moreVertical
                |> FeatherIcons.withSize 18
                |> Common.wrapIcon
                    [ T.mx_2
                    , T.my_1
                    , T.pointer_events_none
                    , T.text_base_500
                    ]

        filename item =
            Html.div
                [ T.flex
                , T.items_center
                , T.ml_2
                , T.mr_auto
                , T.text_base
                , T.text_purple

                -- Dark mode
                ------------
                , T.dark__border_base_800
                , T.dark__text_white
                ]
                [ -----------------------------------------
                  -- Label
                  -----------------------------------------
                  Html.span
                    [ T.flex_auto, T.truncate ]
                    [ Html.text item.nameProperties.base

                    --
                    , case item.nameProperties.extension of
                        "" ->
                            nothing

                        ext ->
                            Drive.extension [] ext
                    ]
                ]

        menuAndFilenameButton item =
            Html.button
                [ item
                    |> Drive.ContextMenu.item
                        ContextMenu.TopLeft
                        { isGroundFloor = Common.isGroundFloor model }
                    |> ShowContextMenu
                    |> M.onClick

                --
                , T.appearance_none
                , T.cursor_pointer
                , T.flex
                , T.flex_row
                , T.flex_shrink_0
                , T.items_center
                , T.mr_auto
                ]
                (List.concat
                    [ [ dotsIcon ]
                    , Common.when model.sidebarExpanded
                        [ filename item ]
                    ]
                )

        menuAndFilename =
            model.directoryList
                |> Result.unwrap [] Drive.Item.Inventory.selectionItems
                |> List.head
                |> Maybe.map menuAndFilenameButton
                |> Maybe.withDefault nothing
    in
    [ menuAndFilename
    , Drive.controlExpand { expanded = model.sidebarExpanded }
    , Drive.controlClose
    ]


editorFooterItems : Sidebar.EditorModel -> List (Html Msg)
editorFooterItems editor =
    let
        { isDisabled, title } =
            if editor.text /= editor.originalText then
                { isDisabled = False
                , title = "Save changes"
                }

            else
                { isDisabled = True
                , title = "Changes are saved"
                }
    in
    [ Html.button
        [ E.onClick (SidebarMsg Sidebar.PlaintextEditorSave)
        , A.title title
        , A.disabled isDisabled

        --
        , T.antialiased
        , T.appearance_none
        , T.bg_purple
        , S.default_transition_duration
        , T.font_semibold
        , T.flex
        , T.flex_row
        , T.items_center
        , T.leading_normal
        , T.outline_none
        , T.px_4
        , T.py_2
        , T.relative
        , T.rounded
        , T.text_tiny
        , T.text_white
        , T.tracking_wider
        , T.transition_colors
        , T.uppercase

        --
        , T.disabled__bg_white
        , T.disabled__text_base_400
        , T.focus__shadow_outline

        -- Dark mode
        ------------
        , T.dark__disabled__bg_base_900
        ]
        [ Common.loadingAnimationWithAttributes
            [ T.mr_2
            , if editor.isSaving then
                T.inline

              else
                T.hidden
            ]
            { size = 18 }
        , Html.text "Save"
        ]
    , Html.button
        [ E.onClick CloseSidebar
        , T.outline_none
        , T.px_4
        , T.py_2
        , T.rounded
        , T.text_base_400
        , T.text_tiny
        , T.tracking_wide
        , T.uppercase

        --
        , T.focus__shadow_outline
        ]
        [ Html.text "Cancel" ]
    ]



-- ADD / CREATE


addOrCreate : Sidebar.AddOrCreateModel -> Model -> Html Msg
addOrCreate addOrCreateModel model =
    Html.div
        []
        [ Drive.sidebarControls
            { above = False
            , controls =
                List.append
                    (if Common.isSingleFileView model then
                        [ Drive.controlExpand { expanded = model.sidebarExpanded } ]

                     else
                        []
                    )
                    [ Drive.controlClose ]
            }

        --
        , addOrCreateForm addOrCreateModel model
        ]


addOrCreateForm : Sidebar.AddOrCreateModel -> Model -> Html Msg
addOrCreateForm addOrCreateModel model =
    let
        title t =
            Html.div
                [ T.font_display
                , T.font_medium
                , T.mb_3
                , T.text_base_500
                , T.text_lg

                -- Dark mode
                ------------
                , T.dark__text_base_400
                ]
                [ Html.text t ]
    in
    Html.div
        [ T.px_5
        , T.py_5

        -- Responsive
        -------------
        , T.sm__px_8
        , T.sm__py_8
        ]
        [ -----------------------------------------
          -- Create
          -----------------------------------------
          title "Create a folder or file"
        , let
            createMsg =
                case addOrCreateModel.kind of
                    Directory ->
                        CreateFolder

                    _ ->
                        CreateFile
          in
          Html.div
            [ T.flex
            , T.flex_wrap

            -- Responsive
            -------------
            , T.sm__flex_no_wrap
            ]
            [ Html.div
                [ T.flex_1
                , T.relative
                ]
                [ S.textField
                    [ E.onEnter createMsg
                    , E.onInput GotAddOrCreateInput
                    , A.placeholder "Magic Box"
                    , A.value addOrCreateModel.input

                    --
                    , T.w_full
                    ]
                    []

                -- Kind selector
                ----------------
                , Html.button
                    [ addOrCreateModel.kind
                        |> Drive.ContextMenu.kind ContextMenu.TopCenterWithoutOffset
                        |> ShowContextMenu
                        |> M.onClick

                    --
                    , T.absolute
                    , T.bg_base_300
                    , T.cursor_pointer
                    , T.flex
                    , T.font_medium
                    , T.items_center
                    , T.mr_4
                    , T.neg_translate_y_1over2
                    , T.px_2
                    , T.py_px
                    , T.right_0
                    , T.rounded_full
                    , T.text_base_500
                    , T.text_xs
                    , T.top_1over2
                    , T.transform
                    , T.uppercase
                    , T.z_10

                    -- Focus
                    --------
                    , T.focus__outline_none
                    , T.focus__bg_purple_tint
                    , T.focus__text_purple_shade

                    -- Dark mode
                    ------------
                    , T.dark__bg_base_600
                    , T.dark__text_base_400

                    --
                    , T.dark__focus__bg_purple_shade
                    , T.dark__focus__text_purple_tint
                    ]
                    [ addOrCreateModel.kind
                        |> Drive.Item.kindIcon
                        |> FeatherIcons.withSize 11
                        |> FeatherIcons.toHtml []
                        |> List.singleton
                        |> Html.span [ T.mr_1 ]
                    , addOrCreateModel.kind
                        |> Drive.Item.generateExtensionForKindShortDescription
                        |> Html.text
                        |> List.singleton
                        |> Html.span []
                    ]
                ]

            -- Button
            ---------
            , case String.trim addOrCreateModel.input of
                "" ->
                    Html.nothing

                _ ->
                    S.buttonWithNode
                        Html.button
                        [ E.onClick createMsg

                        --
                        , T.bg_purple
                        , T.mt_4
                        , T.text_sm
                        , T.w_full

                        -- Responsive
                        -------------
                        , T.sm__ml_3
                        , T.sm__mt_0
                        , T.sm__w_auto
                        ]
                        [ if addOrCreateModel.isCreating then
                            Html.span
                                [ T.flex
                                , T.items_center
                                , T.justify_center
                                ]
                                [ Common.loadingAnimationWithAttributes
                                    [ T.text_opacity_60
                                    , T.text_white
                                    ]
                                    { size = 16 }
                                ]

                          else
                            Html.text "Create"
                        ]
            ]

        -----------------------------------------
        -- Add
        -----------------------------------------
        , Html.div
            [ T.mt_12 ]
            [ title "Add files" ]

        --
        , Html.div
            [ T.relative
            , T.text_center
            ]
            [ Html.node
                "fs-content-uploader"
                [ E.on "changeBlobs" Common.blobUrlsDecoder

                --
                , A.style "min-height" "108px"
                , A.style "padding-top" (ifThenElse model.sidebarExpanded "19%" "22.5%")

                --
                , T.border_2
                , T.border_dashed
                , T.border_base_300
                , T.block
                , T.cursor_pointer
                , T.h_0
                , T.overflow_hidden
                , T.rounded

                -- Dark mode
                ------------
                , T.dark__border_base_800
                ]
                []

            --
            , Html.div
                [ T.absolute
                , T.flex
                , T.font_light
                , T.italic
                , T.justify_center
                , T.leading_tight
                , T.left_1over2
                , T.neg_translate_x_1over2
                , T.neg_translate_y_1over2
                , T.pointer_events_none
                , T.px_4
                , T.text_base_400
                , T.top_1over2
                , T.transform
                , T.truncate
                , T.w_full

                -- Dark mode
                ------------
                , T.dark__text_base_500
                ]
                [ Html.text "Click to choose, or drop some files"
                ]
            ]
        ]



-- DETAILS


detailsForSelection : { paths : List (Path Encapsulated), showPreviewOverlay : Bool } -> Model -> Html Msg
detailsForSelection { showPreviewOverlay } model =
    Html.div
        [ T.flex
        , T.flex_col
        , T.h_full
        , T.items_center
        , T.justify_center
        , T.px_4
        , T.py_6
        ]
        [ model.directoryList
            |> Result.toMaybe
            |> Maybe.map
                Drive.Item.Inventory.selectionItems
            |> Maybe.map
                (Html.Lazy.lazy7
                    Details.view
                    (Routing.isAuthenticatedTree model.authenticated model.route)
                    (Common.isGroundFloor model)
                    (Common.isSingleFileView model)
                    model.currentTime
                    model.sidebarExpanded
                    showPreviewOverlay
                )
            |> Maybe.withDefault
                nothing
        ]



-- UTILITIES


onCtrlS : msg -> Html.Attribute msg
onCtrlS message =
    let
        ensureEquals value decoder =
            Decode.andThen
                (\val ->
                    if val == value then
                        Decode.succeed ()

                    else
                        Decode.fail "Unexpecated value"
                )
                decoder
    in
    E.custom "keydown"
        (Decode.map2
            (\_ _ ->
                { message = message
                , stopPropagation = True
                , preventDefault = True
                }
            )
            (Decode.field "key" Decode.string |> ensureEquals "s")
            (Decode.field "ctrlKey" Decode.bool |> ensureEquals True)
        )
