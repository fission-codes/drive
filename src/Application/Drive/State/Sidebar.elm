module Drive.State.Sidebar exposing (..)

import Drive.Item as Item
import Drive.Sidebar as Sidebar
import Ports
import Radix exposing (..)
import Return


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
                        Ports.fsWriteItemUtf8
                            { pathSegments = Item.pathSegments editPlaintext.path
                            , text = editorModel.text
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
