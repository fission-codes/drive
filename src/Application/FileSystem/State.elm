module FileSystem.State exposing (..)

import Browser.Dom as Dom
import Debouncing
import Drive.Item as Item exposing (Kind(..))
import Drive.Item.Inventory as Inventory
import Drive.Sidebar as Sidebar
import FileSystem
import FileSystem.Actions
import Json.Decode as Json
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Return
import Return.Extra as Return
import Routing
import Task
import Webnative.Path as Path exposing (Encapsulated, Path)
import Webnative.Path.Encapsulated as Path
import Webnative.Path.Extra as Path



-- 🐚


gotDirectoryList : Json.Value -> Manager
gotDirectoryList json model =
    let
        path =
            json
                |> Json.decodeValue (Json.field "path" Path.decoder)
                |> Result.withDefault (Path.encapsulate Path.root)

        floor =
            Path.length path + 1
    in
    if Just path == Routing.treePath model.route then
        gotDirectoryList_ path floor json model

    else
        Return.singleton model


gotDirectoryList_ : Path Encapsulated -> Int -> Json.Value -> Manager
gotDirectoryList_ path floor json model =
    json
        |> Json.decodeValue (Json.field "results" Json.value)
        |> Result.withDefault json
        |> Json.decodeValue (Json.list FileSystem.itemDecoder)
        |> Result.map (List.map Item.fromFileSystem)
        |> Result.mapError Json.errorToString
        |> (\result ->
                let
                    maybeRootCid =
                        json
                            |> Json.decodeValue (Json.field "rootCid" Json.string)
                            |> Result.toMaybe
                            |> Maybe.orElse model.fileSystemCid
                in
                result
                    |> Result.map
                        ({ isGroundFloor = floor == 1 }
                            |> Item.sortingFunction
                            |> List.sortWith
                        )
                    |> Result.map
                        (\items ->
                            { floor = floor
                            , items = items
                            , selection = []
                            }
                        )
                    |> Result.andThen
                        (\inventory ->
                            model.route
                                |> Routing.treePath
                                |> Result.fromMaybe "WrongRoute"
                                |> Result.map
                                    (\routePath ->
                                        Inventory.autoSelectOnSingleFileView
                                            routePath
                                            inventory
                                    )
                        )
                    |> (\directoryList ->
                            let
                                paths =
                                    directoryList
                                        |> Result.map (.items >> List.map .path)
                                        |> Result.withDefault []
                            in
                            { model
                                | directoryList = directoryList
                                , fileSystemCid = maybeRootCid
                                , fileSystemStatus = FileSystem.Ready
                                , showLoadingOverlay = False
                                , sidebar =
                                    case Result.map .selection directoryList of
                                        Ok [] ->
                                            Nothing

                                        Ok _ ->
                                            sidebarForDirectoryList directoryList paths

                                        Err _ ->
                                            Nothing
                                , sidebarExpanded =
                                    case List.map Path.kind paths of
                                        [ Path.File ] ->
                                            True

                                        _ ->
                                            False
                            }
                       )
           )
        |> Return.singleton
        |> Return.andThen Debouncing.cancelLoading
        |> Return.effect_
            -- Might need to load content for sidebar editor
            (\newModel ->
                case newModel.sidebar of
                    Just (Sidebar.EditPlaintext props) ->
                        FileSystem.Actions.readUtf8
                            { path =
                                props.path
                            , tag =
                                { path = props.path }
                                    |> Sidebar.LoadedFile
                                    |> SidebarTag
                            }

                    _ ->
                        Cmd.none
            )
        |> Return.command
            -- Scroll back up
            (Task.attempt
                (always Bypass)
                (Dom.setViewport 0 0)
            )


gotError : String -> Manager
gotError error model =
    Return.singleton
        { model
            | fileSystemCid = Nothing
            , fileSystemStatus = FileSystem.Error error
        }



-- 🛠


sidebarForDirectoryList directoryList paths =
    case
        List.map
            (\i -> ( Path.kind i.path, i, Item.canBeOpenedWithEditor i ))
            (Result.withDefault [] <| Result.map .items directoryList)
    of
        [ ( Path.File, i, True ) ] ->
            Maybe.map
                (\path ->
                    Sidebar.EditPlaintext
                        { path = path
                        , editor = Nothing
                        }
                )
                (Path.toFile i.path)

        [ ( Path.File, _, False ) ] ->
            paths
                |> Sidebar.details
                |> Just

        _ ->
            Nothing
