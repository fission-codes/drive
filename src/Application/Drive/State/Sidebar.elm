module Drive.State.Sidebar exposing (..)

import Drive.Sidebar as Sidebar
import Ports
import Radix exposing (..)
import Return


update : Sidebar.Msg -> Sidebar.Model -> Manager
update msg sidebar model =
    case ( sidebar.mode, msg ) of
        ( Sidebar.EditPlaintext (Just editorModel), Sidebar.PlaintextEditorInput content ) ->
            { model
                | sidebar =
                    Just
                        { sidebar
                            | mode =
                                Sidebar.EditPlaintext
                                    (Just
                                        { editorModel
                                            | text = content
                                        }
                                    )
                        }
            }
                |> Return.singleton

        ( Sidebar.EditPlaintext (Just editorModel), Sidebar.PlaintextEditorSave ) ->
            if editorModel.text /= editorModel.originalText then
                Ports.fsWriteItemUtf8
                    { pathSegments =
                        -- TODO philipp: use a library function instead
                        String.split "/" sidebar.path
                    , text = editorModel.text
                    }
                    |> Return.return
                        { model
                            | sidebar =
                                Just
                                    { sidebar
                                        | mode =
                                            Sidebar.EditPlaintext
                                                (Just
                                                    { editorModel
                                                        | originalText = editorModel.text
                                                    }
                                                )
                                    }
                        }

            else
                model
                    |> Return.singleton

        ( Sidebar.Details detailsModel, Sidebar.DetailsShowPreviewOverlay ) ->
            { model
                | sidebar =
                    Just
                        { sidebar
                            | mode =
                                Sidebar.Details
                                    { detailsModel
                                        | showPreviewOverlay = True
                                    }
                        }
            }
                |> Return.singleton

        ( _, _ ) ->
            Return.singleton model
