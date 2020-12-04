module Drive.View.Sidebar exposing (view)

import Common exposing (ifThenElse)
import Common.View as Common
import ContextMenu
import Drive.ContextMenu
import Drive.Item exposing (Item, Kind(..))
import Drive.Item.Inventory
import Drive.Sidebar as Sidebar
import Drive.View.Common as Drive
import Drive.View.Details as Details
import FeatherIcons
import FileSystem
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
import Url.Builder



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
        , T.bg_gray_900
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
        , T.dark__bg_darkness_below
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
                    , T.px_8
                    , T.pt_8
                    , T.resize_none
                    , T.text_gray_100

                    --
                    , T.h_full
                    , T.w_full

                    -- Focus Styles
                    ---------------
                    , T.appearance_none
                    , T.outline_none
                    , T.focus__shadow_inner_outline

                    -- Dark mode
                    ------------
                    , T.dark__text_gray_500
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
                            [ T.text_gray_400 ]
                            { size = 24 }
                        ]
                    ]
        , Html.div
            [ T.flex
            , T.flex_shrink_0
            , T.h_12
            , T.items_center
            , T.justify_start
            , T.mt_px
            , T.py_2
            , T.relative
            , T.space_x_2
            ]
            (List.append
                [ Html.div
                    [ T.absolute
                    , T.border_t
                    , T.border_gray_300
                    , T.left_0
                    , T.opacity_10
                    , T.right_0
                    , T.top_0
                    ]
                    []
                ]
                (maybeEditor
                    |> Maybe.map editorFooterItems
                    |> Maybe.withDefault []
                )
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
                    , T.text_gray_300
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
                , T.dark__border_darkness_above
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
        , T.bg_purple_shade
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
        , T.focus__shadow_outline

        --
        , T.disabled__bg_gray_600
        , T.dark__disabled__bg_gray_200
        , T.disabled__text_gray_400
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
        , T.text_gray_400
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
                , T.text_gray_300
                , T.text_lg

                -- Dark mode
                ------------
                , T.dark__text_gray_400
                ]
                [ Html.text t ]

        addButton icon attributes content =
            Html.button
                (List.append attributes
                    [ T.appearance_none
                    , T.bg_purple
                    , T.px_4
                    , T.mt_5
                    , T.mr_5
                    , T.my_auto
                    , T.h_10
                    , T.rounded
                    , T.text_gray_900
                    , T.text_sm
                    , T.font_display
                    , T.flex
                    , T.flex_row
                    , T.items_center

                    -- Focus Styles
                    ---------------
                    , T.appearance_none
                    , T.outline_none
                    , T.focus__shadow_outline
                    , T.active__bg_purple_shade
                    ]
                )
                ((icon
                    |> FeatherIcons.withSize 16
                    |> Common.wrapIcon [ T.mr_2 ]
                 )
                    :: content
                )
    in
    Html.div
        [ T.px_8
        , T.py_8
        ]
        [ -----------------------------------------
          -- Create
          -----------------------------------------
          title "Create a file or folder"
        , S.textField
            [ A.placeholder "Magic Box"
            , E.onInput GotAddOrCreateInput
            , T.w_full
            , A.value addOrCreateModel.input
            ]
            []
        , Html.div
            [ T.flex
            , T.flex_row
            , T.flex_wrap
            ]
            [ addButton FeatherIcons.folderPlus
                [ E.onClick (CreateFileOrFolder Nothing) ]
                [ Html.text "New Folder" ]
            , addButton FeatherIcons.filePlus
                [ E.onClick (CreateFileOrFolder (Just { extension = "txt" })) ]
                [ Html.text "New"
                , Drive.extension [] "TXT"
                ]
            , addButton FeatherIcons.filePlus
                [ E.onClick (CreateFileOrFolder (Just { extension = "html" })) ]
                [ Html.text "New"
                , Drive.extension [] "HTML"
                ]
            , addButton FeatherIcons.filePlus
                [ E.onClick (CreateFileOrFolder (Just { extension = "md" })) ]
                [ Html.text "New"
                , Drive.extension [] "MD"
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
                , T.border_gray_500
                , T.block
                , T.cursor_pointer
                , T.h_0
                , T.overflow_hidden
                , T.rounded

                -- Dark mode
                ------------
                , T.dark__border_darkness_above
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
                , T.text_gray_400
                , T.top_1over2
                , T.transform
                , T.truncate
                , T.w_full

                -- Dark mode
                ------------
                , T.dark__text_gray_300
                ]
                [ Html.text "Click to choose, or drop some files"
                ]
            ]
        ]



-- DETAILS


detailsForSelection : { paths : List String, showPreviewOverlay : Bool } -> Model -> Html Msg
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
            decoder
                |> Decode.andThen
                    (\val ->
                        if val == value then
                            Decode.succeed ()

                        else
                            Decode.fail "Unexpecated value"
                    )
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
