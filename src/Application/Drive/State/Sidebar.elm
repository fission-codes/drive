module Drive.State.Sidebar exposing (..)

import Drive.Sidebar as Sidebar
import Ports
import Radix exposing (..)
import Return


update : Sidebar.Msg -> Sidebar.Model -> Manager
update msg sidebar model =
    case msg of
        Sidebar.PlaintextEditorInput content ->
            case sidebar.mode of
                Sidebar.EditPlaintext editorModel ->
                    { model
                        | sidebar =
                            Just
                                { sidebar
                                    | mode =
                                        Sidebar.EditPlaintext
                                            { editorModel
                                                | text = content
                                            }
                                }
                    }
                        |> Return.singleton

                _ ->
                    model
                        |> Return.singleton

        Sidebar.PlaintextEditorSave ->
            case sidebar.mode of
                Sidebar.EditPlaintext editorModel ->
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
                                                        { editorModel | originalText = editorModel.text }
                                            }
                                }

                    else
                        model
                            |> Return.singleton

                _ ->
                    model
                        |> Return.singleton
