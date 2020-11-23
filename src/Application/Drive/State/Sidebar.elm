module Drive.State.Sidebar exposing (..)

import Drive.Item as Item
import Drive.Sidebar as Sidebar
import Ports
import Radix exposing (..)
import Return


update : Sidebar.Msg -> Sidebar.Model -> Manager
update msg sidebar model =
    case ( sidebar.mode, msg ) of
        ( Sidebar.EditPlaintext (Just editorModel), Sidebar.PlaintextEditorInput content ) ->
            { editorModel
                | text = content
                , isSaving = False
            }
                |> Just
                |> Sidebar.EditPlaintext
                |> (\newMode -> { sidebar | mode = newMode })
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })
                |> Return.singleton

        ( Sidebar.EditPlaintext (Just editorModel), Sidebar.PlaintextEditorSave ) ->
            if editorModel.text /= editorModel.originalText then
                Ports.fsWriteItemUtf8
                    { pathSegments = Item.pathSegments sidebar.path
                    , text = editorModel.text
                    }
                    |> Return.return
                        ({ editorModel
                            | originalText = editorModel.text
                            , isSaving = True
                         }
                            |> Just
                            |> Sidebar.EditPlaintext
                            |> (\newMode -> { sidebar | mode = newMode })
                            |> Just
                            |> (\newSidebar -> { model | sidebar = newSidebar })
                        )

            else
                model
                    |> Return.singleton

        ( Sidebar.Details detailsModel, Sidebar.DetailsShowPreviewOverlay ) ->
            { detailsModel | showPreviewOverlay = True }
                |> Sidebar.Details
                |> (\newMode -> { sidebar | mode = newMode })
                |> Just
                |> (\newSidebar -> { model | sidebar = newSidebar })
                |> Return.singleton

        ( _, _ ) ->
            Return.singleton model
