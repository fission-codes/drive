module FileSystem.State exposing (..)

import Browser.Dom as Dom
import Debouncing
import Drive.Item
import Drive.Item.Inventory as Inventory
import Drive.Sidebar as Sidebar
import FileSystem
import Json.Decode as Json
import List.Extra as List
import Maybe.Extra as Maybe
import Radix exposing (..)
import Return
import Return.Extra as Return
import Routing
import Task



-- 🐚


gotDirectoryList : Json.Value -> Manager
gotDirectoryList json model =
    let
        pathSegments =
            json
                |> Json.decodeValue
                    (Json.field "pathSegments" <| Json.list Json.string)
                |> Result.withDefault
                    []

        floor =
            List.length pathSegments + 1
    in
    if pathSegments == Routing.treePathSegments model.route then
        gotDirectoryList_ pathSegments floor json model

    else
        Return.singleton model


gotDirectoryList_ : List String -> Int -> Json.Value -> Manager
gotDirectoryList_ pathSegments floor json model =
    json
        |> Json.decodeValue
            (Json.field "results" Json.value)
        |> Result.withDefault
            json
        |> Json.decodeValue (Json.list FileSystem.itemDecoder)
        |> Result.map (List.map Drive.Item.fromFileSystem)
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
                            |> Drive.Item.sortingFunction
                            |> List.sortWith
                        )
                    |> Result.map
                        (\items ->
                            { floor = floor
                            , items = items
                            , selection = []
                            }
                        )
                    |> Result.map
                        (model.route
                            |> Routing.treePathSegments
                            |> Inventory.autoSelectOnSingleFileView
                        )
                    |> (\directoryList ->
                            { model
                                | directoryList = directoryList
                                , fileSystemCid = maybeRootCid
                                , fileSystemStatus = FileSystem.Ready
                                , showLoadingOverlay = False
                            }
                       )
           )
        |> Return.singleton
        |> Return.andThen Debouncing.cancelLoading
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
