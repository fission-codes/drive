module Drive.Sidebar.State exposing (..)

import Drive.Sidebar as Sidebar
import FileSystem.Actions
import Ports
import Radix exposing (..)
import Return exposing (return)
import Routing
import Task
import Webnative
import Webnative.Path as Path


update : Sidebar.Msg -> Sidebar.Model -> Manager
update msg sidebar model =
    case ( sidebar, msg ) of
        -----------------------------------------
        -- Add or create
        -----------------------------------------
        ( Sidebar.AddOrCreate addOrCreate, Sidebar.ClearAddOrCreateInput ) ->
            { addOrCreate | input = "", isCreating = False }
                |> Sidebar.AddOrCreate
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })
                |> refreshDirectory

        -----------------------------------------
        -- Editor
        -----------------------------------------
        ( Sidebar.EditPlaintext editPlaintext, Sidebar.PlaintextEditorInput content ) ->
            case editPlaintext.editor of
                Just editorModel ->
                    { editorModel
                        | text = content
                        , isSaving = False
                    }
                        |> Just
                        |> (\newEditor -> { editPlaintext | editor = newEditor })
                        |> Sidebar.EditPlaintext
                        |> Just
                        |> (\newSidebar -> { model | sidebar = newSidebar })
                        |> Return.singleton

                _ ->
                    Return.singleton model

        ( Sidebar.EditPlaintext editPlaintext, Sidebar.PlaintextEditorSave ) ->
            case ( editPlaintext.editor, model.fileSystemRef ) of
                ( Just editorModel, Just fs ) ->
                    if editorModel.text /= editorModel.originalText then
                        editorModel.text
                            |> FileSystem.Actions.writeUtf8 fs editPlaintext.path
                            |> Task.andThen (\_ -> FileSystem.Actions.publish fs)
                            |> Webnative.attemptTask
                                { ok = always (SidebarMsg <| Sidebar.SavedFile { path = editPlaintext.path })
                                , error = HandleWebnativeError
                                }
                            |> return
                                ({ editorModel
                                    | originalText = editorModel.text
                                    , isSaving = True
                                 }
                                    |> Just
                                    |> (\e -> { editPlaintext | editor = e })
                                    |> Sidebar.EditPlaintext
                                    |> Just
                                    |> (\s -> { model | sidebar = s })
                                )

                    else
                        Return.singleton model

                _ ->
                    Return.singleton model

        -----------------------------------------
        -- Editor → Loaded File
        -----------------------------------------
        ( Sidebar.EditPlaintext editPlaintext, Sidebar.LoadedFile { path } text ) ->
            if path /= editPlaintext.path then
                Return.singleton model

            else
                { text = text
                , originalText = text
                , isSaving = False
                }
                    |> Just
                    |> (\newEditor -> { editPlaintext | editor = newEditor })
                    |> Sidebar.EditPlaintext
                    |> Just
                    |> (\newSidebar -> { model | sidebar = newSidebar })
                    |> Return.singleton

        -----------------------------------------
        -- Editor → Saved File
        -----------------------------------------
        ( Sidebar.EditPlaintext editPlaintext, Sidebar.SavedFile { path } ) ->
            if path /= editPlaintext.path then
                Return.singleton model

            else
                case editPlaintext.editor of
                    Just editorModel ->
                        { editorModel
                            | isSaving = False
                            , originalText = editorModel.text
                        }
                            |> Just
                            |> (\newEditor -> { editPlaintext | editor = newEditor })
                            |> Sidebar.EditPlaintext
                            |> Just
                            |> (\newSidebar -> { model | sidebar = newSidebar })
                            |> Return.singleton

                    Nothing ->
                        Return.singleton model

        -----------------------------------------
        -- Details
        -----------------------------------------
        ( Sidebar.Details detailsModel, Sidebar.DetailsShowPreviewOverlay ) ->
            { detailsModel | showPreviewOverlay = True }
                |> Sidebar.Details
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })
                |> Return.singleton

        -----------------------------------------
        -- 🦉
        -----------------------------------------
        ( _, _ ) ->
            Return.singleton model



-- 🛠


refreshDirectory : Manager
refreshDirectory model =
    case Routing.treePath model.route of
        Just path ->
            { path = Path.encode path }
                |> Ports.fsListDirectory
                |> return model

        Nothing ->
            Return.singleton model
