module FileSystem.State exposing (..)

import Browser.Dom as Dom
import Debouncing
import Drive.Item as Item exposing (Item, Kind(..))
import Drive.Item.Inventory as Inventory
import Drive.Sidebar as Sidebar
import Drive.State as Drive
import FileSystem
import FileSystem.Actions
import Json.Decode as Json
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Return exposing (return)
import Return.Extra as Return
import Routing
import Task
import Webnative
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
                    maybeIndex =
                        -- We might need to automatically select a specific file in the tree
                        json
                            |> Json.decodeValue (Json.field "index" Json.int)
                            |> Result.toMaybe

                    maybeRootCid =
                        json
                            |> Json.decodeValue (Json.field "rootCid" Json.string)
                            |> Result.toMaybe
                            |> Maybe.orElse model.fileSystemCid

                    readOnly =
                        json
                            |> Json.decodeValue (Json.field "readOnly" Json.bool)
                            |> Result.withDefault False

                    replaceSymlinkPath =
                        -- Path of the symlink we need to replace
                        json
                            |> Json.decodeValue (Json.field "replaceSymlink" Path.decoder)
                            |> Result.toMaybe
                in
                result
                    |> Result.map
                        ({ isGroundFloor = floor == 1 }
                            |> Item.sortingFunction
                            |> List.sortWith
                        )
                    |> Result.map
                        (\items ->
                            case replaceSymlinkPath of
                                Just symlinkPath ->
                                    model.directoryList
                                        |> Result.map
                                            (.items >> replaceSymlink items symlinkPath)
                                        |> Result.withDefault
                                            items
                                        |> (\i ->
                                                { floor = floor
                                                , items = i
                                                , readOnly = readOnly
                                                , selection = []
                                                }
                                           )

                                Nothing ->
                                    { floor = floor
                                    , items = items
                                    , readOnly = readOnly
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
                    |> (case maybeIndex of
                            Just index ->
                                \newModel ->
                                    model.directoryList
                                        |> Result.map .items
                                        |> Result.withDefault []
                                        |> List.getAt index
                                        |> Maybe.map (\item -> Drive.select index item newModel)
                                        |> Maybe.withDefault (Return.singleton newModel)

                            Nothing ->
                                Return.singleton
                       )
           )
        |> Return.andThen Debouncing.cancelLoading
        |> Return.effect_
            -- Might need to load content for sidebar editor
            (\newModel ->
                case ( newModel.sidebar, newModel.fileSystemRef ) of
                    ( Just (Sidebar.EditPlaintext props), Just fs ) ->
                        props.path
                            |> FileSystem.Actions.readUtf8 fs
                            |> Webnative.attemptTask
                                { ok = SidebarMsg << Sidebar.LoadedFile { path = props.path }
                                , error = HandleWebnativeError
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


replaceSymlink : List Item -> Path Encapsulated -> List Item -> List Item
replaceSymlink newList symlinkPath currentList =
    let
        unwrappedPath =
            Path.unwrap symlinkPath
    in
    currentList
        |> List.foldr
            (\item ( acc, new ) ->
                if item.path == symlinkPath then
                    case List.partition (.path >> Path.unwrap >> (==) unwrappedPath) new of
                        ( n :: _, subset ) ->
                            ( { n | readOnly = True } :: acc, subset )

                        _ ->
                            ( item :: acc, new )

                else
                    ( item :: acc, new )
            )
            ( [], newList )
        |> Tuple.first


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
