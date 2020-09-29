module Drive.State exposing (..)

import Browser.Navigation as Navigation
import Common
import Common.State as Common
import Debouncing
import Dict
import Drive.Item as Item exposing (Item, Kind(..))
import Drive.Modals
import Drive.Sidebar
import File
import File.Download
import FileSystem exposing (Operation(..))
import List.Ext as List
import List.Extra as List
import Notifications
import Ports
import Radix exposing (..)
import Result.Extra as Result
import Return exposing (andThen, return)
import Return.Extra as Return
import Routing
import Toasty
import Url



-- 📣


activateSidebarMode : Drive.Sidebar.Mode -> Manager
activateSidebarMode mode model =
    Return.singleton { model | sidebarMode = mode }


addFiles : { blobs : List { path : String, url : String } } -> Manager
addFiles { blobs } model =
    { blobs = blobs
    , pathSegments = Routing.treePathSegments model.route
    }
        |> Ports.fsAddContent
        |> return { model | fileSystemStatus = FileSystem.Operation AddingFiles }
        -- Notification
        |> Toasty.addConditionalToast
            (\m -> m.fileSystemStatus == FileSystem.Operation AddingFiles)
            Notifications.config
            ToastyMsg
            (Notifications.loadingIndication "Uploading files")


closeSidebar : Manager
closeSidebar model =
    if model.sidebarMode == Drive.Sidebar.defaultMode then
        Return.singleton
            { model
                | expandSidebar = False
                , selectedPath = Nothing
                , showPreviewOverlay = False
            }

    else
        Common.potentiallyRenderMedia
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }


copyPublicUrl : { item : Item, presentable : Bool } -> Manager
copyPublicUrl { item, presentable } model =
    let
        base =
            Common.base { presentable = presentable } model

        notification =
            if presentable then
                "Copied Drive URL to clipboard."

            else
                "Copied Content URL to clipboard."
    in
    item
        |> Item.publicUrl base
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


copyToClipboard : { clip : String, notification : String } -> Manager
copyToClipboard { clip, notification } model =
    clip
        |> Ports.copyToClipboard
        |> Return.return model
        |> Return.command (Ports.showNotification notification)


createDirectory : Manager
createDirectory model =
    case String.trim model.createDirectoryInput of
        "" ->
            Return.singleton model

        directoryName ->
            model.route
                |> Routing.treePathSegments
                |> List.add [ directoryName ]
                |> (\p -> Ports.fsCreateDirectory { pathSegments = p })
                |> return { model | fileSystemStatus = FileSystem.Operation CreatingDirectory }


digDeeper : { directoryName : String } -> Manager
digDeeper { directoryName } model =
    let
        items =
            model.directoryList
                |> Result.map .items
                |> Result.withDefault []

        currentPathSegments =
            Routing.treePathSegments model.route

        pathSegments =
            -- TODO: Not sure why this is here?
            -- case model.ipfs of
            --     Ipfs.AdditionalListing ->
            --         Maybe.withDefault [] (List.init currentPathSegments)
            --
            --     _ ->
            --         currentPathSegments
            currentPathSegments

        updatedItems =
            List.map
                (\i ->
                    if i.name == directoryName then
                        { i | loading = True }

                    else
                        { i | loading = False }
                )
                items

        updatedDirectoryList =
            Result.map (\l -> { l | items = updatedItems }) model.directoryList
    in
    [ directoryName ]
        |> List.append pathSegments
        |> Routing.replaceTreePathSegments model.route
        |> Routing.adjustUrl model.url
        |> Url.toString
        |> Navigation.pushUrl model.navKey
        |> Return.return
            { model
                | directoryList = updatedDirectoryList
                , sidebarMode = Drive.Sidebar.defaultMode
            }


digDeeperUsingSelection : Manager
digDeeperUsingSelection model =
    case ( model.directoryList, model.selectedPath ) of
        ( Ok { items }, Just path ) ->
            items
                |> List.find
                    (.path >> (==) path)
                |> Maybe.map
                    (\item ->
                        if item.kind == Item.Directory then
                            digDeeper { directoryName = item.name } model

                        else
                            Return.singleton model
                    )
                |> Maybe.withDefault
                    (Return.singleton model)

        _ ->
            Return.singleton model


downloadItem : Item -> Manager
downloadItem item model =
    item
        |> Item.pathProperties
        |> Ports.fsDownloadItem
        |> return model


gotCreateDirectoryInput : String -> Manager
gotCreateDirectoryInput input model =
    Return.singleton { model | createDirectoryInput = input }


goUp : { floor : Int } -> Manager
goUp { floor } model =
    if floor >= 0 then
        (case floor of
            0 ->
                []

            x ->
                List.take (x - 1) (Routing.treePathSegments model.route)
        )
            |> Routing.replaceTreePathSegments model.route
            |> Routing.adjustUrl model.url
            |> Url.toString
            |> Navigation.pushUrl model.navKey
            |> Return.return { model | selectedPath = Nothing }
            |> Return.command
                ({ on = True }
                    |> ToggleLoadingOverlay
                    |> Debouncing.loading.provideInput
                    |> Return.task
                )

    else
        Return.singleton model


goUpOneLevel : Manager
goUpOneLevel model =
    model.route
        |> Routing.treePathSegments
        |> List.length
        |> (\x -> goUp { floor = x } model)


removeItem : Item -> Manager
removeItem item model =
    item
        |> Item.pathProperties
        |> Ports.fsRemoveItem
        |> return { model | fileSystemStatus = FileSystem.Operation Deleting }
        -- Notification
        |> Toasty.addConditionalToast
            (\m -> m.fileSystemStatus == FileSystem.Operation Deleting)
            Notifications.config
            ToastyMsg
            (Notifications.loadingIndication <| "Removing “" ++ item.name ++ "”")


renameItem : Item -> Manager
renameItem item model =
    case Maybe.andThen (.state >> Dict.get "name") model.modal of
        Just newName ->
            let
                newNameProps =
                    case item.kind of
                        Directory ->
                            { base = newName
                            , extension = ""
                            }

                        _ ->
                            Item.nameProperties newName

                newDirectoryList =
                    case model.directoryList of
                        Ok a ->
                            a.items
                                |> List.map
                                    (\i ->
                                        if i.id == item.id then
                                            { i | name = newName, nameProperties = newNameProps }

                                        else
                                            i
                                    )
                                |> (\items -> Ok { a | items = items })

                        Err e ->
                            Err e
            in
            { currentPathSegments = String.split "/" item.path
            , pathSegments = Routing.treePathSegments model.route ++ [ newName ]
            }
                |> Ports.fsMoveItem
                |> return { model | directoryList = newDirectoryList }
                |> andThen Common.hideModal

        Nothing ->
            Common.hideModal model


select : Item -> Manager
select item model =
    Common.potentiallyRenderMedia
        { model
            | selectedPath = Just item.path
            , sidebarMode = Drive.Sidebar.DetailsForSelection
        }


selectNextItem : Manager
selectNextItem =
    makeItemSelector
        (\i -> i + 1)
        (\_ -> 0)


selectPreviousItem : Manager
selectPreviousItem =
    makeItemSelector
        (\i -> i - 1)
        (\l -> List.length l - 1)


showPreviewOverlay : Manager
showPreviewOverlay model =
    Return.singleton { model | showPreviewOverlay = True }


showRenameItemModal : Item -> Manager
showRenameItemModal item model =
    Return.singleton { model | modal = Just (Drive.Modals.renameItem item) }


toggleExpandedSidebar : Manager
toggleExpandedSidebar model =
    Return.singleton { model | expandSidebar = not model.expandSidebar }


toggleSidebarMode : Drive.Sidebar.Mode -> Manager
toggleSidebarMode mode model =
    if model.sidebarMode == Drive.Sidebar.defaultMode then
        Return.singleton
            { model
                | expandSidebar = False
                , sidebarMode = mode
            }

    else
        Common.potentiallyRenderMedia
            { model
                | expandSidebar = False
                , sidebarMode = Drive.Sidebar.defaultMode
            }



-- ㊙️


makeItemSelector : (Int -> Int) -> (List Item -> Int) -> Manager
makeItemSelector indexModifier fallbackIndexFn model =
    case ( model.directoryList, model.selectedPath ) of
        ( Ok { items }, Just selectedPath ) ->
            items
                |> List.findIndex (.path >> (==) selectedPath)
                |> Maybe.map indexModifier
                |> Maybe.andThen (\idx -> List.getAt idx items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        ( Ok { items }, Nothing ) ->
            items
                |> List.getAt (fallbackIndexFn items)
                |> Maybe.map (\item -> select item model)
                |> Maybe.withDefault (Return.singleton model)

        _ ->
            Return.singleton model
