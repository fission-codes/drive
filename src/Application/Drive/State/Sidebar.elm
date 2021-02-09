module Drive.State.Sidebar exposing (..)

import Drive.Item as Item
import Drive.Sidebar as Sidebar
import FileSystem.Actions
import Radix exposing (..)
import Return
import Wnfs


update : Sidebar.Msg -> Sidebar.Model -> Manager
update msg sidebar model =
    case ( sidebar, msg ) of
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
            case editPlaintext.editor of
                Just editorModel ->
                    if editorModel.text /= editorModel.originalText then
                        FileSystem.Actions.writeUtf8
                            { path = Item.pathSegments editPlaintext.path
                            , tag = SidebarTag (Sidebar.SavedFile { path = editPlaintext.path })
                            , content = editorModel.text
                            }
                            |> Return.return
                                ({ editorModel
                                    | originalText = editorModel.text
                                    , isSaving = True
                                 }
                                    |> Just
                                    |> (\newEditor -> { editPlaintext | editor = newEditor })
                                    |> Sidebar.EditPlaintext
                                    |> Just
                                    |> (\newSidebar -> { model | sidebar = newSidebar })
                                )

                    else
                        model
                            |> Return.singleton

                _ ->
                    Return.singleton model

        ( Sidebar.Details detailsModel, Sidebar.DetailsShowPreviewOverlay ) ->
            { detailsModel | showPreviewOverlay = True }
                |> Sidebar.Details
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })
                |> Return.singleton

        ( _, _ ) ->
            Return.singleton model


updateTag : Sidebar.Tag -> Wnfs.Artifact -> Sidebar.Model -> Manager
updateTag tag artifact sidebarModel model =
    case ( sidebarModel, tag, artifact ) of
        ( Sidebar.EditPlaintext editPlaintext, Sidebar.SavedFile { path }, _ ) ->
            (if path /= editPlaintext.path then
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
            )
                |> Return.command (FileSystem.Actions.publish { tag = UpdatedFilesystem })

        ( _, Sidebar.SavedFile _, _ ) ->
            FileSystem.Actions.publish { tag = UpdatedFilesystem }
                |> Return.return model

        ( Sidebar.EditPlaintext editPlaintext, Sidebar.LoadedFile { path }, Wnfs.Utf8Content text ) ->
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

        ( Sidebar.EditPlaintext _, Sidebar.LoadedFile _, _ ) ->
            Return.singleton model

        ( Sidebar.Details _, _, _ ) ->
            Return.singleton model

        ( Sidebar.AddOrCreate _, _, _ ) ->
            Return.singleton model
